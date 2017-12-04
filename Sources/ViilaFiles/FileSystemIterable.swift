import Foundation

/// Protocol adopted by file system types that may be iterated over (this protocol is an implementation detail)
public protocol FileSystemIterable {
    /// Initialize an instance with a path and a file manager
    init(path: String, using fileManager: FileManager) throws
}