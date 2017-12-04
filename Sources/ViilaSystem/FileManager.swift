import Foundation

extension FileManager {
    func itemKind(atPath path: String) -> FileSystem.Item.Kind? {
        var objCBool: ObjCBool = false
        
        guard fileExists(atPath: path, isDirectory: &objCBool) else {
            return nil
        }

        if objCBool.boolValue {
            return .folder
        }
        
        return .file
    }
    
    func itemNames(inFolderAtPath path: String) -> [String] {
        do {
            return try contentsOfDirectory(atPath: path).sorted()
        } catch {
            return []
        }
    }
    
    func absolutePath(for path: String) throws -> String {
        if path.hasPrefix("/") {
            return try pathByFillingInParentReferences(for: path)
        }
        
        if path.hasPrefix("~") {
            let prefixEndIndex = path.index(after: path.startIndex)
            
            let path = path.replacingCharacters(
                in: path.startIndex..<prefixEndIndex,
                with: ProcessInfo.processInfo.homeFolderPath
            )

            return try pathByFillingInParentReferences(for: path)
        }

        return try pathByFillingInParentReferences(for: path, prependCurrentFolderPath: true)
    }

    func parentPath(for path: String) -> String? {
        guard path != "/" else {
            return nil
        }

        var pathComponents = path.pathComponents

        if path.hasSuffix("/") {
            pathComponents.removeLast(2)
        } else {
            pathComponents.removeLast()
        }

        return pathComponents.joined(separator: "/")
    }

    func pathByFillingInParentReferences(for path: String, prependCurrentFolderPath: Bool = false) throws -> String {
        var path = path
        var filledIn = false

        while let parentReferenceRange = path.range(of: "../") {
            let currentFolderPath = String(path[..<parentReferenceRange.lowerBound])

            guard let currentFolder = try? Folder(path: currentFolderPath) else {
                throw FileSystem.Item.PathError.invalid(path)
            }

            guard let parent = currentFolder.parent else {
                throw FileSystem.Item.PathError.invalid(path)
            }

            path = path.replacingCharacters(in: path.startIndex..<parentReferenceRange.upperBound, with: parent.path)
            filledIn = true
        }

        if prependCurrentFolderPath {
            guard filledIn else {
                return currentDirectoryPath + "/" + path
            }
        }

        return path
    }
}