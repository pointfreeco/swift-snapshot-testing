// swift-tools-version:6.0

import Foundation
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
      name: "InlineSnapshotTesting",
      targets: ["InlineSnapshotTesting"]
    ),
    .library(
      name: "SnapshotTestingCustomDump",
      targets: ["SnapshotTestingCustomDump"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.3"),
    .conditionalPackage(
      url: "https://github.com/swiftlang/swift-syntax",
      envVar: "SWIFT_SYNTAX_VERSION",
      default: "509.0.0..<605.0.0"
    ),
  ],
  targets: [
    .target(
      name: "SnapshotTesting"
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
    .target(
      name: "InlineSnapshotTesting",
      dependencies: [
        "SnapshotTesting",
        "SnapshotTestingCustomDump",
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
    .target(
      name: "SnapshotTestingCustomDump",
      dependencies: [
        "SnapshotTesting",
        .product(name: "CustomDump", package: "swift-custom-dump"),
      ]
    ),
  ],
  swiftLanguageModes: [.v5]
)

extension Package.Dependency {
  static func conditionalPackage(
    url: String,
    envVar: String,
    default versionExpression: String
  ) -> Package.Dependency {
    let versionRangeString = ProcessInfo.processInfo.environment[envVar] ?? versionExpression
    let rangeOperators = ["..<", "..."]
    for op in rangeOperators {
      if versionRangeString.contains(op) {
        let parts = versionRangeString.split(separator: op, maxSplits: 1, omittingEmptySubsequences: true)
          .map(String.init)
        guard
          parts.count == 2,
          let lower = Version(parts[0]),
          let upper = Version(parts[1])
        else {
          fatalError("Invalid version expression format: \(versionRangeString)")
        }
        if op == "..<" {
          return .package(url: url, lower..<upper)
        } else {
          return .package(url: url, lower...upper)
        }
      }
    }
    fatalError("No valid range operator found in expression: \(versionRangeString)")
  }
}
