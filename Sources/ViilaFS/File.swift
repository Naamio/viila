import Foundation

///
/// Class representing a file that's stored by a file system
///
/// You initialize this class with a path, or by asking a folder 
/// to return a file for a given name
///
public final class File: FileSystem.Item, FileSystemIterable {
    /// Error type specific to file-related operations
    public enum Error: Swift.Error, CustomStringConvertible {
        /// Thrown when a file couldn't be written to
        case writeFailed
        /// Thrown when a file couldn't be read, either because it was malformed or because it has been deleted
        case readFailed

        /// A string describing the error
        public var description: String {
            switch self {
            case .writeFailed:
                return "Failed to write to file"
            case .readFailed:
                return "Failed to read file"
            }
        }
    }
    
    /// 
    /// Initialize an instance of this class with a path pointing to a file
    /// 
    ///  - parameter path: The path of the file to create a representation of
    ///  - parameter fileManager: Optionally give a custom file manager to use to look up the file
    /// 
    ///  - throws: `FileSystemItem.Error` in case an empty path was given, or if the path given doesn't
    ///     point to a readable file.
    /// 
    public init(path: String, using fileManager: FileManager = .default) throws {
        try super.init(path: path, kind: .file, using: fileManager)
    }
    
    /// 
    /// Read the data contained within this file
    /// 
    ///  - throws: `File.Error.readFailed` if the file's data couldn't be read
    /// 
    public func read() throws -> Data {
        do {
            return try Data(contentsOf: URL(fileURLWithPath: path))
        } catch {
            throw Error.readFailed
        }
    }

    /// 
    /// Read the data contained within this file, and convert it to a string
    /// 
    ///  - throws: `File.Error.readFailed` if the file's data couldn't be read as a string
    /// 
    public func readAsString(encoding: String.Encoding = .utf8) throws -> String {
        guard let string = try String(data: read(), encoding: encoding) else {
            throw Error.readFailed
        }

        return string
    }

    /// 
    /// Read the data contained within this file, and convert it to an int
    /// 
    ///  - throws: `File.Error.readFailed` if the file's data couldn't be read as an int
    /// 
    public func readAsInt() throws -> Int {
        guard let int = try Int(readAsString()) else {
            throw Error.readFailed
        }

        return int
    }
    
    /// 
    /// Write data to the file, replacing its current content
    /// 
    ///  - parameter data: The data to write to the file
    /// 
    ///  - throws: `File.Error.writeFailed` if the file couldn't be written to
    /// 
    public func write(data: Data) throws {
        do {
            try data.write(to: URL(fileURLWithPath: path))
        } catch {
            throw Error.writeFailed
        }
    }
    
    /// 
    ///  Write a string to the file, replacing its current content
    /// 
    ///   - parameter string: The string to write to the file
    ///   - parameter encoding: Optionally give which encoding that the string should be encoded in (defaults to UTF-8)
    /// 
    ///   - throws: `File.Error.writeFailed` if the string couldn't be encoded, or written to the file
    /// 
    public func write(string: String, encoding: String.Encoding = .utf8) throws {
        guard let data = string.data(using: encoding) else {
            throw Error.writeFailed
        }
        
        try write(data: data)
    }
    
    /// 
    /// Copy this file to a new folder
    /// 
    ///  - parameter folder: The folder that the file should be copy to
    /// 
    ///  - throws: `FileSystem.Item.OperationError.copyFailed` if the file couldn't be copied
    /// 
    @discardableResult public func copy(to folder: Folder) throws -> File {
        let newPath = folder.path + name
        
        do {
            try fileManager.copyItem(atPath: path, toPath: newPath)
            return try File(path: newPath)
        } catch {
            throw OperationError.copyFailed(self)
        }
    }
}