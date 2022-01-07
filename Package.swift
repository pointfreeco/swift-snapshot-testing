// swift-tools-version:5.3

import Foundation
import PackageDescription

let package = Package(
  name: "swift-snapshot-testing",
  platforms: [
    .iOS(.v11),
    .macOS(.v10_10),
    .tvOS(.v11),
    .watchOS(.v7),
  ],
  products: [
    .library(
      name: "SnapshotTesting",
      targets: ["SnapshotTesting"]),
  ],
  targets: [
    .target(name: "SnapshotTesting"),
    .testTarget(name: "SnapshotTestingTests", dependencies: ["SnapshotTesting"]),
  ]
)

if ProcessInfo.processInfo.environment.keys.contains("PF_DEVELOP") {
  package.dependencies.append(
    contentsOf: [
      .package(url: "https://github.com/yonaskolb/XcodeGen.git", .exact("2.15.1")),
    ]
  )
}
