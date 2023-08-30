// swift-tools-version:5.5
import PackageDescription

let package = Package(
  name: "swift-snapshot-testing",
  platforms: [
    .iOS(.v11),
    .macOS(.v10_10),
    .tvOS(.v10),
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
      dependencies: ["SnapshotTesting"],
      exclude: [
        "__Fixtures__",
        "__Snapshots__"
      ]
    )
  ]
)
