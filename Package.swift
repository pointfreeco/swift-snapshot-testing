// swift-tools-version:4.0

import PackageDescription

let package = Package(
  name: "SnapshotTesting",
  products: [
    .library(
      name: "SnapshotTesting",
      targets: ["SnapshotTesting"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-prelude.git", .branch("master")),
  ],
  targets: [
    .target(
      name: "SnapshotTesting",
      dependencies: ["Prelude", "Either"]),
    .testTarget(
      name: "SnapshotTestingTests",
      dependencies: ["SnapshotTesting"]),
  ]
)
