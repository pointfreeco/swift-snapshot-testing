// swift-tools-version:4.0

import PackageDescription

let webViewSnapshotAvailable: Bool
if #available(iOS 11.0, macOS 10.13, *) {
  webViewSnapshotAvailable = true
} else {
  webViewSnapshotAvailable = false
}

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
    dependencies: webViewSnapshotAvailable ? ["Diff", "WKSnapshotConfigurationShim"] : ["Diff"]),
  .testTarget(
    name: "SnapshotTestingTests",
    dependencies: ["SnapshotTesting"]),
  ]
  + (webViewSnapshotAvailable ? [shimTarget] : [])

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
