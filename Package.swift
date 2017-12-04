// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Viila",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "ViilaSystem",
            targets: ["ViilaSystem"]),
        .library(
            name: "ViilaWatch",
            targets: ["ViilaWatch"]),
    ],
    dependencies: [

    ],
    targets: [
         .target(
            name: "ViilaSystem",
            dependencies: []),
        .target(
            name: "ViilaWatch",
            dependencies: []),
        .testTarget(
            name: "ViilaSystemTests",
            dependencies: ["ViilaSystem"]),
        .testTarget(
            name: "ViilaWatchTests",
            dependencies: ["ViilaWatch"])
    ]
)
