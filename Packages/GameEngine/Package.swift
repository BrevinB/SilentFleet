// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GameEngine",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "GameEngine",
            targets: ["GameEngine"]
        ),
    ],
    targets: [
        .target(
            name: "GameEngine",
            dependencies: [],
            path: "Sources/GameEngine"
        ),
        .testTarget(
            name: "GameEngineTests",
            dependencies: ["GameEngine"],
            path: "Tests/GameEngineTests"
        ),
    ]
)
