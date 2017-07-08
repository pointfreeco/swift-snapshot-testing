// swift-tools-version:4.0

import PackageDescription

let package = Package(
  name: "SnapshotAssertion",
  products: [
    .library(
      name: "SnapshotAssertion",
      targets: ["SnapshotAssertion"]),
  ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "SnapshotAssertion",
      dependencies: []),
    .testTarget(
      name: "SnapshotAssertionTests",
      dependencies: ["SnapshotAssertion"]),
  ]
)
