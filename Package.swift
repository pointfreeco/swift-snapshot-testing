// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "swift-snapshot-testing",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: products,
  dependencies: dependencies,
  targets: inlineSnapshottingTargets + [
    .target(name: "SnapshotTesting"),
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

let products: [Product]
let inlineSnapshottingTargets: [Target]
let dependencies: [Package.Dependency]
#if swift(>=5.7)
  products = [
    .library(name: "SnapshotTesting", targets: ["SnapshotTesting"]),
    .library(name: "InlineSnapshotTesting", targets: ["InlineSnapshotTesting"]),
  ]
  dependencies = [
    .package(url: "https://github.com/apple/swift-syntax", from: "509.0.0")
  ]
  inlineSnapshottingTargets = [
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
  ]
#else
  products = [
    .library(name: "SnapshotTesting", targets: ["SnapshotTesting"])
  ]
  dependencies = []
  additionalTargets = []
#endif
