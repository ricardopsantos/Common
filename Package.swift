// swift-tools-version: 6.0

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
                // Tools version 6.0 would otherwise opt the whole package into
                // the Swift 6 language mode and its strict concurrency checking.
                .swiftLanguageMode(.v5),
            ]
        ),
        .testTarget(
            name: "CommonTests",
            dependencies: [
                "Common",
            ],
            swiftSettings: [
                .define("IN_PACKAGE_CODE"),
                .swiftLanguageMode(.v5),
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
