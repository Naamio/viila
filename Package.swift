// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Viila",
    products: [
        .library(
            name: "Viila",
            targets: ["ViilaFS"]),
    ],
    dependencies: [

    ],
    targets: [
        .target(
            name: "ViilaFS",
            dependencies: []),
        .testTarget(
            name: "ViilaFSTests",
            dependencies: ["ViilaFS"]),
    ]
)
