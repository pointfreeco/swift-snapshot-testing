// swift-tools-version:4.0

import PackageDescription

#if os(Linux)
let isLinux = true
#else
let isLinux = false
#endif

let shimTarget = Target.target(
  name: "WKSnapshotConfigurationShim",
  dependencies: []
)

let targets: [Target] = [
  .target(
    name: "Diff",
    dependencies: []),
  .target(
    name: "SnapshotTesting",
    dependencies: isLinux ? ["Diff"] : ["Diff", "WKSnapshotConfigurationShim"]),
  .testTarget(
    name: "SnapshotTestingTests",
    dependencies: ["SnapshotTesting"]),
  ]
  + (isLinux ? [] : [shimTarget])

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
