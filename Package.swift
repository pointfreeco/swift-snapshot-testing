// swift-tools-version:5.0

import PackageDescription

let package = Package(
  name: "SnapshotTesting",
  products: [
    .library(
      name: "SnapshotTesting",
      targets: ["SnapshotTesting"]),
  ],
  dependencies: [
    .package(url: "https://github.com/yonaskolb/XcodeGen.git", from: "2.3.0"),
  ],
  targets: [
    .target(
      name: "SnapshotTesting",
      dependencies: []),
    .testTarget(
      name: "SnapshotTestingTests",
      dependencies: ["SnapshotTesting"]),
  ]
)
