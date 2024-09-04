// swift-tools-version:5.10
import Foundation
import PackageDescription

let package = Package(
  name: "SnapshotTesting",
  platforms: [
    .iOS(.v13),
    .macOS(.v12),
    .tvOS(.v13)
  ],
  products: [
    .library(
      name: "SnapshotTesting",
      targets: ["SnapshotTesting"]),
  ],
  dependencies: [
    .package(url: "https://github.com/awxkee/jxl-coder-swift.git", from: "1.7.3")
  ],
  targets: [
    .target(
      name: "SnapshotTesting",
      dependencies: [
        .product(name: "JxlCoder", package: "jxl-coder-swift")
      ]),
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
