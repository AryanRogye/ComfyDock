// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Parser",
    products: [
        .library(name: "Parser", targets: ["Parser"]),
    ],
    targets: [
        // Swift target depends on the Obj-C target
        .target(
            name: "Parser",
            dependencies: ["ParserCore"]
        ),
        // Obj-C (Clang) target: headers go under `include`
        .target(
            name: "ParserCore",
            publicHeadersPath: "include"
        ),
        .executableTarget(
            name: "ParserCLI",
            dependencies: ["Parser"]
        ),
    ]
)
