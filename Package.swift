// swift-tools-version:5.10

import PackageDescription

let package = Package(
  name: "swift-snapshot-testing",
  platforms: [
    .iOS(.v13),
    .macOS(.v12),
    .tvOS(.v13),
    .watchOS(.v8),
  ],
  products: [
    .library(
      name: "SnapshotTesting",
      targets: ["SnapshotTesting"]
    ),
    .library(
      name: "JPEGXLImageSerializer",
      targets: ["JPEGXLImageSerializer"]
    ),
    .library(
      name: "InlineSnapshotTesting",
      targets: ["InlineSnapshotTesting"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"601.0.0-prerelease"),
    .package(url: "https://github.com/awxkee/jxl-coder-swift.git", from: "1.7.3")
  ],
  targets: [
    .target(
      name: "SnapshotTesting",
      dependencies: [
        "ImageSerializer"
      ]
    ),
    .target(
      name: "ImageSerializer"
    ),
    .target(
      name: "JPEGXLImageSerializer",
      dependencies: [
        "ImageSerializer",
        .product(name: "JxlCoder", package: "jxl-coder-swift")
      ]
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
