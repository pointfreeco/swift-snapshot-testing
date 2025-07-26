// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "swift-snapshot-testing",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "XCSnapshotTesting",
            targets: ["XCSnapshotTesting"]
        ),
        .library(
            name: "SnapshotTesting",
            targets: ["SnapshotTesting"]
        ),
        .library(
            name: "SnapshotTestingCustomDump",
            targets: ["SnapshotTestingCustomDump"]
        ),
        .library(
            name: "InlineSnapshotTesting",
            targets: ["InlineSnapshotTesting"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.3"),
        .package(url: "https://github.com/swiftlang/swift-syntax", "601.0.0"..<"602.0.0"),
    ],
    targets: [
        /* DEPRECATED TARGETS */
        .target(
            name: "_SnapshotTesting",
            path: "Sources/Deprecated/SnapshotTesting",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "_SnapshotTestingCustomDump",
            dependencies: [
                "_SnapshotTesting",
                .product(name: "CustomDump", package: "swift-custom-dump"),
            ],
            path: "Sources/Deprecated/SnapshotTestingCustomDump",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "_InlineSnapshotTesting",
            dependencies: [
                "_SnapshotTesting",
                "_SnapshotTestingCustomDump",
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ],
            path: "Sources/Deprecated/InlineSnapshotTesting",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        /* TARGETS */
        .target(
            name: "XCSnapshotTesting",
            dependencies: ["_SnapshotTesting"]
        ),
        .target(
            name: "SnapshotTesting",
            dependencies: ["XCSnapshotTesting"]
        ),
        .target(
            name: "SnapshotTestingCustomDump",
            dependencies: [
                "XCSnapshotTesting",
                .product(name: "CustomDump", package: "swift-custom-dump"),
                "_SnapshotTestingCustomDump",
            ]
        ),
        .target(
            name: "InlineSnapshotTesting",
            dependencies: [
                "SnapshotTesting",
                "SnapshotTestingCustomDump",
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                "_InlineSnapshotTesting",
            ]
        ),
        /* DEPRECATED TESTS */
        .testTarget(
            name: "_SnapshotTestingTests",
            dependencies: ["XCSnapshotTesting", "SnapshotTesting"],
            path: "Tests/Deprecated/SnapshotTestingTests",
            exclude: [
                "__Fixtures__",
                "__Snapshots__",
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "_InlineSnapshotTestingTests",
            dependencies: ["InlineSnapshotTesting"],
            path: "Tests/Deprecated/InlineSnapshotTestingTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        /* TESTS */
        .testTarget(
            name: "XCSnapshotTestingTests",
            dependencies: ["XCSnapshotTesting"],
            exclude: [
                "__Fixtures__",
                "__Snapshots__",
            ]
        ),
        .testTarget(
            name: "SnapshotTestingTests",
            dependencies: ["SnapshotTesting"],
            exclude: ["__Snapshots__"]
        ),
        .testTarget(
            name: "SnapshotTestingCustomDumpTests",
            dependencies: [
                "SnapshotTestingCustomDump"
            ]
        ),
        .testTarget(
            name: "InlineSnapshotTestingTests",
            dependencies: [
                "InlineSnapshotTesting"
            ]
        ),
    ]
)
