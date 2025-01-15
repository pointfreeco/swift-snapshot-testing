// swift-tools-version:5.7

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
      name: "SnapshotTesting",
      targets: ["SnapshotTesting"]
    ),
    .library(
      name: "SnapshotTestingPlugin",
      targets: ["SnapshotTestingPlugin"]
    ),
    .library(
      name: "ImageSerializationPlugin",
      targets: ["ImageSerializationPlugin"]
    ),
    .library(
      name: "InlineSnapshotTesting",
      targets: ["InlineSnapshotTesting"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"601.0.0-prerelease")
  ],
  targets: [
    .target(
      name: "SnapshotTesting",
      dependencies: [
        "ImageSerializationPlugin",
        "SnapshotTestingPlugin"
      ]
    ),
    .target(name: "SnapshotTestingPlugin"),
    .target(
      name: "ImageSerializationPlugin",
      dependencies: ["SnapshotTestingPlugin"]
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
    .testTarget(
      name: "InlineSnapshotTestingTests",
      dependencies: [
        "InlineSnapshotTesting"
      ]
    ),
    .testTarget(
      name: "SnapshotTestingTests",
      dependencies: [
        "SnapshotTesting"
      ],
      exclude: [
        "__Fixtures__",
        "__Snapshots__",
      ]
    ),
  ]
)
