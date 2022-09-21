// swift-tools-version:5.5
import PackageDescription

let package = Package(
  name: "swift-snapshot-testing",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13)
  ],
  products: [
    .library(
      name: "SnapshotTesting",
      targets: ["SnapshotTesting"]
    ),
  ],
  targets: [
    .target(name: "SnapshotTesting"),
    .testTarget(
      name: "SnapshotTestingTests",
      dependencies: ["SnapshotTesting"]
    )
  ]
)
