// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "swift-snapshot-testing",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
  ],
  products: [
    .library(
      name: "SnapshotTesting",
      targets: ["SnapshotTesting"]
    ),
    .library(
      name: "InlineSnapshotTesting",
      targets: ["InlineSnapshotTesting"]
    ),
    .library(
      name: "MacroSnapshotTesting",
      targets: ["MacroSnapshotTesting"]
    ),
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-syntax.git",
      from: "509.0.0-swift-DEVELOPMENT-SNAPSHOT-2023-07-10-a"
    ),
  ],
  targets: [
    .target(
      name: "SnapshotTesting"
    ),
    .target(
      name: "InlineSnapshotTesting",
      dependencies: [
        "SnapshotTesting",
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "MacroSnapshotTesting",
      dependencies: [
        "InlineSnapshotTesting",
        .product(name: "SwiftBasicFormat", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "SnapshotTestingTests",
      dependencies: [
        "InlineSnapshotTesting",
        "SnapshotTesting",
      ],
      exclude: [
        "__Fixtures__",
        "__Snapshots__",
      ]
    ),
  ]
)
