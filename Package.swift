// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Common",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "Common",
            targets: ["Common"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/realm/SwiftLint.git", from: "0.55.1"),
        .package(url: "https://github.com/Quick/Nimble", from: "13.3.0"),
    ],
    targets: [
        .target(
            name: "Common",
            dependencies: [],
            resources: [
                .process("Resources/Assets.xcassets"),
                .process("Resources/CommonDB.xcdatamodeld"),
                .process("Resources/google.co.uk.cer"),
            ],
            swiftSettings: [
                .define("IN_PACKAGE_CODE"),
            ],
            plugins: [
                //   .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")
            ]
        ),
        .testTarget(
            name: "CommonTests",
            dependencies: [
                "Common",
                .product(name: "Nimble", package: "Nimble"),
            ],
            swiftSettings: [
                .define("IN_PACKAGE_CODE"),
            ],
            plugins: [
                // .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")
            ]
        ),
    ]
)

// Keep your unsafe flags
for target in package.targets {
    target.swiftSettings = target.swiftSettings ?? []
    target.swiftSettings?.append(
        .unsafeFlags([
            "-Xfrontend",
            "-warn-long-function-bodies=200",
            "-Xfrontend",
            "-warn-long-expression-type-checking=200",
        ])
    )
}
