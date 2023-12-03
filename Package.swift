// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport

let package = Package(
  name: "swift-snapshot-testing",
  platforms: [
    .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)
  ],
  products: [
    .library(
      name: "SnapshotTesting",
      targets: ["SnapshotTesting"]
    ),
    .library(
      name: "SnapshotMacros",
      targets: ["SnapshotMacros"]
    ),
    .library(
      name: "InlineSnapshotTesting",
      targets: ["InlineSnapshotTesting"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-syntax.git", "508.0.1"..<"510.0.0")
  ],
  targets: [
    .macro(
        name: "SnapshotTestingMacros",
        dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
      ]
    ),
    .target(
      name: "SnapshotTesting"
    ),
    .target(
      name: "SnapshotMacros",
      dependencies: [
        "SnapshotTesting",
        "SnapshotTestingMacros"
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
      name: "SnapshotTestingMacrosTests",
      dependencies: [
        "SnapshotMacros",
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ],
      exclude: [
        "__Fixtures__",
        "__Snapshots__",
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
