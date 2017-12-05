# Viila

<p align="center">
    <a href="https://swift.org/package-manager">
        <img src="https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat" alt="Swift Package Manager" />
    </a>
    <a href="https://img.shields.io/badge/os-macOS-green.svg?style=flag">
        <img src="https://img.shields.io/badge/os-macOS-green.svg?style=flag" alt="macOS" />
    </a>
    <a href="https://img.shields.io/badge/os-linux-green.svg?style=flag">
        <img src="https://img.shields.io/badge/os-linux-green.svg?style=flag" alt="Linux" />
    </a>
    <a href="https://opensource.org/licenses/MIT">
        <img src="https://img.shields.io/badge/License-MIT-yellow.svg?style=flat" alt="License: MIT" />
    </a>
    <a href="https://twitter.com/omnijarstudio">
        <img src="https://img.shields.io/badge/contact-@omnijarstudio-blue.svg?style=flat" alt="Twitter: @omnijarstudio" />
    </a>
</p>

**Viila** is a Swift library that provides a compact and efficient way to handle filesystem tasks in Swift. It’s primarily aimed at Swift scripting and tooling, but can also be embedded in applications that need to access the file system. It's essentially a thin wrapper around the `FileManager` APIs that `Foundation` provides.

## Features

- [X] Modern, object-oriented API for accessing, reading and writing files & folders.
- [X] Unified, simple `do, try, catch` error handling.
- [X] Easily construct recursive and flat sequences of files and folders.

## Examples

Iterate over the files contained in a folder:
```swift
for file in try Folder(path: "MyFolder").files {
    print(file.name)
}
```

Rename all files contained in a folder:
```swift
try Folder(path: "MyFolder").files.enumerated().forEach { (index, file) in
    try file.rename(to: file.nameWithoutExtension + "\(index)")
}
```

Recursively iterate over all folders in a tree:
```swift
Folder.home.makeSubfolderSequence(recursive: true).forEach { folder in
    print("Name : \(folder.name), parent: \(folder.parent)")
}
```

Create, write and delete files and folders:
```swift
let folder = try Folder(path: "/users/tauno/folder")
let file = try folder.createFile(named: "file.json")
try file.write(string: "{\"hello\": \"world\"}")
try file.delete()
try folder.delete()
```

Move all files in a folder to another:
```swift
let originFolder = try Folder(path: "/users/tauno/folderA")
let targetFolder = try Folder(path: "/users/tauno/folderB")
try originFolder.files.move(to: targetFolder)
```

Easy access to system folders:
```swift
Folder.current
Folder.temporary
Folder.home
```

## Usage

Files can be easily used in either a Swift script, command-line tool or in an app for iOS, macOS, tvOS or Linux.

### In an application

- Use Swift Package manager to include Viila as a dependency in your project.

## Questions or feedback?

Feel free to [open an issue](https://github.com/Naamio/viila/issues/new), or find us [@omnijarstudio on Twitter](https://twitter.com/omnijarstudio).

