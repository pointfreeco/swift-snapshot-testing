// swift-tools-version:5.0
import Foundation
import PackageDescription

let package = Package(
  name: "SnapshotTesting",
  platforms: [
    .iOS(.v11),
    .macOS(.v10_10),
    .tvOS(.v10)
  ],
  products: [
    .library(
      name: "SnapshotTesting",
      targets: ["SnapshotTesting"]),
  ],
  dependencies: [
    .package(url: "https://github.com/JWStaiert/SnapshotCompare.git", from: Version("0.1.0"))
  ],
  targets: [
    .target(
      name: "SnapshotTesting",
      dependencies: ["SnapshotCompare"]),
    .testTarget(
      name: "SnapshotTestingTests",
      dependencies: ["SnapshotTesting"]),
  ]
)

if ProcessInfo.processInfo.environment.keys.contains("PF_DEVELOP") {
  package.dependencies.append(
    contentsOf: [
      .package(url: "https://github.com/yonaskolb/XcodeGen.git", .exact("2.15.1")),
    ]
  )
}
