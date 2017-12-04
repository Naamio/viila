import Foundation

// MARK: - Public API

/**
 *  Class that represents a file system
 *
 *  You only have to interact with this class in case you want to get a reference
 *  to a system folder (like the temporary cache folder, or the user's home folder).
 *
 *  To open other files & folders, use the `File` and `Folder` class respectively.
 */
public class FileSystem {
    fileprivate let fileManager: FileManager

    /**
     *  Class that represents an item that's stored by a file system
     *
     *  This is an abstract base class, that has two publically initializable concrete
     *  implementations, `File` and `Folder`. You can use the APIs available on this class
     *  to perform operations that are supported by both files & folders.
     */
    public class Item: Equatable, CustomStringConvertible {
        /// Errror type used for invalid paths for files or folders
        public enum PathError: Error, Equatable, CustomStringConvertible {
            /// Thrown when an empty path was given when initializing a file
            case empty
            /// Thrown when an item of the expected type wasn't found for a given path (contains the path)
            case invalid(String)
        
            /// Operator used to compare two instances for equality
            public static func ==(lhs: PathError, rhs: PathError) -> Bool {
                switch lhs {
                case .empty:
                    switch rhs {
                    case .empty:
                        return true
                    case .invalid(_):
                        return false
                    }
                case .invalid(let pathA):
                    switch rhs {
                    case .empty:
                        return false
                    case .invalid(let pathB):
                        return pathA == pathB
                    }
                }
            }
        
            /// A string describing the error
            public var description: String {
                switch self {
                case .empty:
                    return "Empty path given"
                case .invalid(let path):
                    return "Invalid path given: \(path)"
                }
            }
        }
        
        /// Error type used for failed operations run on files or folders
        public enum OperationError: Error, Equatable, CustomStringConvertible {
            /// Thrown when a file or folder couldn't be renamed (contains the item)
            case renameFailed(Item)
            /// Thrown when a file or folder couldn't be moved (contains the item)
            case moveFailed(Item)
            /// Thrown when a file or folder couldn't be copied (contains the item)
            case copyFailed(Item)
            /// Thrown when a file or folder couldn't be deleted (contains the item)
            case deleteFailed(Item)
            
            /// Operator used to compare two instances for equality
            public static func ==(lhs: OperationError, rhs: OperationError) -> Bool {
                switch lhs {
                case .renameFailed(let itemA):
                    switch rhs {
                    case .renameFailed(let itemB):
                        return itemA == itemB
                    case .moveFailed(_):
                        return false
                    case .copyFailed(_):
                        return false
                    case .deleteFailed(_):
                        return false
                    }
                case .moveFailed(let itemA):
                    switch rhs {
                    case .renameFailed(_):
                        return false
                    case .moveFailed(let itemB):
                        return itemA == itemB
                    case .copyFailed(_):
                        return false
                    case .deleteFailed(_):
                        return false
                    }
                case .copyFailed(let itemA):
                    switch rhs {
                    case .renameFailed(_):
                        return false
                    case .moveFailed(_):
                        return false
                    case .copyFailed(let itemB):
                        return itemA == itemB
                    case .deleteFailed(_):
                        return false
                    }
                case .deleteFailed(let itemA):
                    switch rhs {
                    case .renameFailed(_):
                        return false
                    case .moveFailed(_):
                        return false
                    case .copyFailed(_):
                        return false
                    case .deleteFailed(let itemB):
                        return itemA == itemB
                    }
                }
            }

            /// A string describing the error
            public var description: String {
                switch self {
                case .renameFailed(let item):
                    return "Failed to rename item: \(item)"
                case .moveFailed(let item):
                    return "Failed to move item: \(item)"
                case .copyFailed(let item):
                    return "Failed to copy item: \(item)"
                case .deleteFailed(let item):
                    return "Failed to delete item: \(item)"
                }
            }
        }
        
        /// Operator used to compare two instances for equality
        public static func ==(lhs: Item, rhs: Item) -> Bool {
            guard lhs.kind == rhs.kind else {
                return false
            }
            
            return lhs.path == rhs.path
        }
        
        /// The path of the item, relative to the root of the file system
        public private(set) var path: String
        
        /// The name of the item (including any extension)
        public private(set) var name: String

        /// The name of the item (excluding any extension)
        public var nameExcludingExtension: String {
            guard let `extension` = `extension` else {
                return name
            }

            let endIndex = name.index(name.endIndex, offsetBy: -`extension`.count - 1)
            return String(name[..<endIndex])
        }
        
        /// Any extension that the item has
        public var `extension`: String? {
            let components = name.components(separatedBy: ".")
            
            guard components.count > 1 else {
                return nil
            }
            
            return components.last
        }

        /// The date when the item was last modified
        public private(set) lazy var modificationDate: Date = self.loadModificationDate()

        /// The folder that the item is contained in, or `nil` if this item is the root folder of the file system
        public var parent: Folder? {
            return fileManager.parentPath(for: path).flatMap { parentPath in
                return try? Folder(path: parentPath, using: fileManager)
            }
        }
        
        /// A string describing the item
        public var description: String {
            return "\(kind)(name: \(name), path: \(path))"
        }
        
        fileprivate let kind: Kind
        let fileManager: FileManager
        
        init(path: String, kind: Kind, using fileManager: FileManager) throws {
            guard !path.isEmpty else {
                throw PathError.empty
            }
            
            let path = try fileManager.absolutePath(for: path)
            
            guard fileManager.itemKind(atPath: path) == kind else {
                throw PathError.invalid(path)
            }
            
            self.path = path
            self.fileManager = fileManager
            self.kind = kind
            
            let pathComponents = path.pathComponents
            
            switch kind {
            case .file:
                self.name = pathComponents.last!
            case .folder:
                self.name = pathComponents[pathComponents.count - 2]
            }
        }
        
        /**
         *  Rename the item
         *
         *  - parameter newName: The new name that the item should have
         *  - parameter keepExtension: Whether the file should keep the same extension as it had before (defaults to `true`)
         *
         *  - throws: `FileSystem.Item.OperationError.renameFailed` if the item couldn't be renamed
         */
        public func rename(to newName: String, keepExtension: Bool = true) throws {
            guard let parent = parent else {
                throw OperationError.renameFailed(self)
            }
            
            var newName = newName
            
            if keepExtension {
                if let `extension` = `extension` {
                    let extensionString = ".\(`extension`)"
                    
                    if !newName.hasSuffix(extensionString) {
                        newName += extensionString
                    }
                }
            }
            
            var newPath = parent.path + newName
            
            if kind == .folder && !newPath.hasSuffix("/") {
                newPath += "/"
            }
            
            do {
                try fileManager.moveItem(atPath: path, toPath: newPath)
                
                name = newName
                path = newPath
            } catch {
                throw OperationError.renameFailed(self)
            }
        }
        
        /**
         *  Move this item to a new folder
         *
         *  - parameter newParent: The new parent folder that the item should be moved to
         *
         *  - throws: `FileSystem.Item.OperationError.moveFailed` if the item couldn't be moved
         */
        public func move(to newParent: Folder) throws {
            let newPath = newParent.path + name
            
            do {
                try fileManager.moveItem(atPath: path, toPath: newPath)
                path = newPath
            } catch {
                throw OperationError.moveFailed(self)
            }
        }
        
        /**
         *  Delete the item from disk
         *
         *  The item will be immediately deleted. If this is a folder, all of its contents will also be deleted.
         *
         *  - throws: `FileSystem.Item.OperationError.deleteFailed` if the item coudn't be deleted
         */
        public func delete() throws {
            do {
                try fileManager.removeItem(atPath: path)
            } catch {
                throw OperationError.deleteFailed(self)
            }
        }
    }
    
    /// A reference to the temporary folder used by this file system
    public var temporaryFolder: Folder {
        return try! Folder(path: NSTemporaryDirectory(), using: fileManager)
    }
    
    /// A reference to the current user's home folder
    public var homeFolder: Folder {
        return try! Folder(path: ProcessInfo.processInfo.homeFolderPath, using: fileManager)
    }

    // A reference to the folder that is the current working directory
    public var currentFolder: Folder {
        return try! Folder(path: "")
    }
    
    /**
     *  Initialize an instance of this class
     *
     *  - parameter fileManager: Optionally give a custom file manager to use to perform operations
     */
    public init(using fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /**
     *  Create a new file at a given path
     *
     *  - parameter path: The path at which a file should be created. If the path is missing intermediate
     *                    parent folders, those will be created as well.
     *
     *  - throws: `File.Error.writeFailed`
     *
     *  - returns: The file that was created
     */
    @discardableResult public func createFile(at path: String, contents: Data = Data()) throws -> File {
        let path = try fileManager.absolutePath(for: path)

        guard let parentPath = fileManager.parentPath(for: path) else {
            throw File.Error.writeFailed
        }

        do {
            let index = path.index(path.startIndex, offsetBy: parentPath.count + 1)
            let name = String(path[index...])
            return try createFolder(at: parentPath).createFile(named: name, contents: contents)
        } catch {
            throw File.Error.writeFailed
        }
    }

    /**
     *  Either return an existing file, or create a new one, at a given path.
     *
     *  - parameter path: The path for which a file should either be returned or created at. If the folder
     *                    is missing, any intermediate parent folders will also be created.
     *
     *  - throws: `File.Error.writeFailed`
     *
     *  - returns: The file that was either created or found.
     */
    @discardableResult public func createFileIfNeeded(at path: String, contents: Data = Data()) throws -> File {
        if let existingFile = try? File(path: path, using: fileManager) {
            return existingFile
        }

        return try createFile(at: path, contents: contents)
    }

    /**
     *  Create a new folder at a given path
     *
     *  - parameter path: The path at which a folder should be created. If the path is missing intermediate
     *                    parent folders, those will be created as well.
     *
     *  - throws: `Folder.Error.creatingFolderFailed`
     *
     *  - returns: The folder that was created
     */
    @discardableResult public func createFolder(at path: String) throws -> Folder {
        do {
            let path = try fileManager.absolutePath(for: path)
            try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            return try Folder(path: path, using: fileManager)
        } catch {
            throw Folder.Error.creatingFolderFailed
        }
    }

    /**
     *  Either return an existing folder, or create a new one, at a given path
     *
     *  - parameter path: The path for which a folder should either be returned or created at. If the folder
     *                    is missing, any intermediate parent folders will also be created.
     *
     *  - throws: `Folder.Error.creatingFolderFailed`
     */
    @discardableResult public func createFolderIfNeeded(at path: String) throws -> Folder {
        if let existingFolder = try? Folder(path: path, using: fileManager) {
            return existingFolder
        }

        return try createFolder(at: path)
    }
}

// MARK: - Private

extension FileSystem.Item {
    enum Kind: CustomStringConvertible {
        case file
        case folder
        
        var description: String {
            switch self {
            case .file:
                return "File"
            case .folder:
                return "Folder"
            }
        }
    }

    func loadModificationDate() -> Date {
        let attributes = try! fileManager.attributesOfItem(atPath: path)
        return attributes[FileAttributeKey.modificationDate] as! Date
    }
}

extension String {
    var pathComponents: [String] {
        return components(separatedBy: "/")
    }
}

extension ProcessInfo {
    var homeFolderPath: String {
        return environment["HOME"]!
    }
}

#if os(Linux)
private extension ObjCBool {
    var boolValue: Bool { return Bool(self) }
}
#endif

#if !os(Linux)
extension FileSystem {
    /// A reference to the document folder used by this file system.
    public var documentFolder: Folder? {
        guard let url = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
            return nil
        }
        
        return try? Folder(path: url.path, using: fileManager)
    }
    
    /// A reference to the library folder used by this file system.
    public var libraryFolder: Folder? {
        guard let url = try? fileManager.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
            return nil
        }
        
        return try? Folder(path: url.path, using: fileManager)
    }
}
#endif
