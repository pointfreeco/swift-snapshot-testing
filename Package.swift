// swift-tools-version:4.0

import PackageDescription

let snapshotTestingDependencies: [Target.Dependency]
#if os(Linux)
  snapshotTestingDependencies = []
#else
  snapshotTestingDependencies = ["WKSnapshotConfigurationShim"]
#endif

let sharedTargets: [Target] = [
  .target(
    name: "Diff",
    dependencies: []),
  .target(
    name: "SnapshotTesting",
    dependencies: snapshotTestingDependencies),
  .testTarget(
    name: "SnapshotTestingTests",
    dependencies: ["SnapshotTesting"]),
]

#if os(Linux)
  let targets = sharedTargets
#else
  let targets = sharedTargets + [
    .target(
      name: "WKSnapshotConfigurationShim",
      dependencies: []),
  ]
#endif

let package = Package(
  name: "SnapshotTesting",
  products: [
    .library(
      name: "SnapshotTesting",
      targets: ["SnapshotTesting"]),
  ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "Diff",
      dependencies: []),
    .target(
      name: "SnapshotTesting",
      dependencies: ["Diff", "WKSnapshotConfigurationShim"]),
    .testTarget(
      name: "SnapshotTestingTests",
      dependencies: ["SnapshotTesting"]),
    .target(
      name: "WKSnapshotConfigurationShim",
      dependencies: []),
  ]
)
