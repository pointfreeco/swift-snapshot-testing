// swift-tools-version:4.0

import PackageDescription

let targets: [Target] = [
  .target(
    name: "Diff",
    dependencies: []),
  .target(
    name: "SnapshotTesting",
    dependencies: ["Diff"]),
  .testTarget(
    name: "SnapshotTestingTests",
    dependencies: ["SnapshotTesting"]),
]

let package = Package(
  name: "SnapshotTesting",
  products: [
    .library(
      name: "SnapshotTesting",
      targets: ["SnapshotTesting"]),
  ],
  dependencies: [
  ],
  targets: targets
)
