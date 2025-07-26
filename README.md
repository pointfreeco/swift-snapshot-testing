# 📸 SnapshotTesting

[![CI](https://github.com/pointfreeco/swift-snapshot-testing/workflows/CI/badge.svg)](https://actions-badge.atrox.dev/pointfreeco/swift-snapshot-testing/goto)
[![Slack](https://img.shields.io/badge/slack-chat-informational.svg?label=Slack&logo=slack)](http://pointfree.co/slack-invite)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-snapshot-testing%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/pointfreeco/swift-snapshot-testing)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-snapshot-testing%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/pointfreeco/swift-snapshot-testing)

Delightful Swift snapshot testing.

## Usage

Once [installed](#installation), no additional configuration is required. You can import the `SnapshotTesting` module and call the `assert` function when using Swift Testing.

```swift
import SnapshotTesting

@MainActor
final class MyViewControllerTests: XCTestCase {
    func testMyViewController() async throws {
        let vc = MyViewController()
        try await assert(of: vc, as: .image)
    }
}
```

> When an assertion runs for the first time, a snapshot is automatically recorded to disk, and the test will fail, printing the file path of the newly recorded reference.

> Repeat test runs will load this reference and compare it with the runtime value. If they don't match, the test will fail and describe the difference.

You can record a new reference by customizing snapshots inline with the assertion or using the `withTestingEnvironment` method.

## Snapshot Anything

SnapshotTesting isn't limited to `UIView`s and `UIViewController`s. You can snapshot test any value on any Swift platform!

```swift
try await assert(of: user, as: .json)
try await assert(of: user, as: .plist)
try await assert(of: user, as: .customDump)
```

## Documentation

The latest documentation is available for both main components of the framework:

- For **XCSnapshotTesting** (the core snapshot testing functionality):
  [XCSnapshotTesting Documentation](https://swiftpackageindex.com/pointfreeco/swift-snapshot-testing/main/documentation/xcsnapshottesting)

- For **SnapshotTesting** (the Swift Testing integration and utilities):
  [SnapshotTesting Documentation](https://swiftpackageindex.com/pointfreeco/swift-snapshot-testing/main/documentation/snapshottesting)

These documents provide detailed information on how to use each component effectively in your testing workflows.

## Installation

### Xcode

1. From the **File** menu, navigate to **Swift Packages** and select **Add Package Dependency…**.
2. Enter the package repository URL: `https://github.com/pointfreeco/swift-snapshot-testing`.
3. Confirm the version and let Xcode resolve the package.
4. Ensure SnapshotTesting is added to a test target.

### Swift Package Manager

Add the package as a dependency in `Package.swift`:

```swift
dependencies: [
  .package(
    url: "https://github.com/pointfreeco/swift-snapshot-testing",
    from: "2.0.0"
  ),
]
```

Next, add `SnapshotTesting` to your test target:

```swift
targets: [
  .testTarget(
    name: "MyAppTests",
    dependencies: [
      "MyApp",
      .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
    ]
  )
]
```

## Features

- **Versatile Snapshot Strategies**: Test any value, not just UI components.
- **Custom Snapshot Strategies**: Create your own snapshot strategies.
- **No Configuration Required**: Snapshots are saved alongside your tests automatically.
- **Device-Agnostic Snapshots**: Render views for specific devices from a single simulator.
- **Xcode Integration**: Image differences are captured as XCTest attachments.
- **Cross-Platform Support**: Supports iOS, macOS, tvOS, and more.
- **SceneKit, SpriteKit, and WebKit Support**: Test these specialized views.
- **Codable Support**: Snapshot encodable data structures into JSON and property list representations.
- **Custom Diff Tool Integration**: Configure failure messages to print diff commands for tools like Kaleidoscope.

## Plugins

- [AccessibilitySnapshot](https://github.com/cashapp/AccessibilitySnapshot) adds easy regression
  testing for iOS accessibility.

- [AccessibilitySnapshotColorBlindness](https://github.com/Sherlouk/AccessibilitySnapshotColorBlindness)
  adds snapshot strategies for color blindness simulation on iOS views, view controllers and images.

- [GRDBSnapshotTesting](https://github.com/SebastianOsinski/GRDBSnapshotTesting) adds snapshot
  strategy for testing SQLite database migrations made with [GRDB](https://github.com/groue/GRDB.swift).

- [Nimble-SnapshotTesting](https://github.com/tahirmt/Nimble-SnapshotTesting) adds
  [Nimble](https://github.com/Quick/Nimble) matchers for SnapshotTesting to be used by Swift
  Package Manager.

- [Prefire](https://github.com/BarredEwe/Prefire) generating Snapshot Tests via
  [Swift Package Plugins](https://github.com/apple/swift-package-manager/blob/main/Documentation/Plugins.md)
  using SwiftUI `Preview`

- [PreviewSnapshots](https://github.com/doordash-oss/swiftui-preview-snapshots) share `View`
  configurations between SwiftUI Previews and snapshot tests and generate several snapshots with a
  single test assertion.

- [swift-html](https://github.com/pointfreeco/swift-html) is a Swift DSL for type-safe,
  extensible, and transformable HTML documents and includes an `HtmlSnapshotTesting` module to
  snapshot test its HTML documents.

- [swift-snapshot-testing-nimble](https://github.com/Killectro/swift-snapshot-testing-nimble) adds
  [Nimble](https://github.com/Quick/Nimble) matchers for SnapshotTesting.

- [swift-snapshot-testing-stitch](https://github.com/Sherlouk/swift-snapshot-testing-stitch/) adds
  the ability to stitch multiple UIView's or UIViewController's together in a single test.

- [SnapshotTestingDump](https://github.com/tahirmt/swift-snapshot-testing-dump) Adds support to
  use [swift-custom-dump](https://github.com/pointfreeco/swift-custom-dump/) by using `customDump`
  strategy for `Any`

- [SnapshotTestingHEIC](https://github.com/alexey1312/SnapshotTestingHEIC) adds image support
using the HEIC storage format which reduces file sizes in comparison to PNG.

- [SnapshotVision](https://github.com/gregersson/swift-snapshot-testing-vision) adds snapshot
  strategy for text recognition on views and images. Uses Apples Vision framework.

Have you written your own SnapshotTesting plug-in?
[Add it here](https://github.com/pointfreeco/swift-snapshot-testing/edit/master/README.md) and
submit a pull request!

## Related Tools

- [`iOSSnapshotTestCase`](https://github.com/uber/ios-snapshot-test-case/) helped introduce screen
    shot testing to a broad audience in the iOS community. Experience with it inspired the creation
    of this library.

- [Jest](https://jestjs.io) brought generalized snapshot testing to the JavaScript community with
  a polished user experience. Several features of this library (diffing, automatically capturing
  new snapshots) were directly influenced.

## Learn More

SnapshotTesting was designed with [witness-oriented programming](https://www.pointfree.co/episodes/ep39-witness-oriented-library-design).

This concept (and more) are explored thoroughly in a series of episodes on
[Point-Free](https://www.pointfree.co), a video series exploring functional programming and Swift
hosted by [Brandon Williams](https://twitter.com/mbrandonw) and
[Stephen Celis](https://twitter.com/stephencelis).

Witness-oriented programming and the design of this library was explored in the following
[Point-Free](https://www.pointfree.co) episodes:

  - [Episode 33](https://www.pointfree.co/episodes/ep33-protocol-witnesses-part-1): Protocol Witnesses: Part 1
  - [Episode 34](https://www.pointfree.co/episodes/ep34-protocol-witnesses-part-1): Protocol Witnesses: Part 2
  - [Episode 35](https://www.pointfree.co/episodes/ep35-advanced-protocol-witnesses-part-1): Advanced Protocol Witnesses: Part 1
  - [Episode 36](https://www.pointfree.co/episodes/ep36-advanced-protocol-witnesses-part-2): Advanced Protocol Witnesses: Part 2
  - [Episode 37](https://www.pointfree.co/episodes/ep37-protocol-oriented-library-design-part-1): Protocol-Oriented Library Design: Part 1
  - [Episode 38](https://www.pointfree.co/episodes/ep38-protocol-oriented-library-design-part-2): Protocol-Oriented Library Design: Part 2
  - [Episode 39](https://www.pointfree.co/episodes/ep39-witness-oriented-library-design): Witness-Oriented Library Design
  - [Episode 40](https://www.pointfree.co/episodes/ep40-async-functional-refactoring): Async Functional Refactoring
  - [Episode 41](https://www.pointfree.co/episodes/ep41-a-tour-of-snapshot-testing): A Tour of Snapshot Testing 🆓

<a href="https://www.pointfree.co/episodes/ep41-a-tour-of-snapshot-testing">
  <img alt="video poster image" src="https://d3rccdn33rt8ze.cloudfront.net/episodes/0041.jpeg" width="480">
</a>

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
