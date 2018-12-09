# 📸 SnapshotTesting

[![Swift 4.2](https://img.shields.io/badge/swift-4.2-ED523F.svg?style=flat)](https://swift.org/download/) [![iOS/macOS/tvOS CI](https://img.shields.io/circleci/project/github/pointfreeco/swift-snapshot-testing/master.svg?label=ios/macos/tvos)](https://circleci.com/gh/pointfreeco/swift-snapshot-testing) [![Linux CI](https://img.shields.io/travis/pointfreeco/swift-snapshot-testing/master.svg?label=linux)](https://travis-ci.org/pointfreeco/swift-nonempty) [![@pointfreeco](https://img.shields.io/badge/contact-@pointfreeco-5AA9E7.svg?style=flat)](https://twitter.com/pointfreeco)

Delightful Swift snapshot testing.

<!--
![An example of a snapshot failure in Xcode.](.github/snapshot-test-1.png)
-->

## Usage

Once [installed](#installation), _no additional configuration is required_. You can import the `SnapshotTesting` module and call the `assertSnapshot` function.

``` swift
import SnapshotTesting
import XCTest

class MyViewControllerTests: XCTestCase {
  func testMyViewController() {
    let vc = MyViewController()

    assertSnapshot(matching: vc, as: .image)
  }
}
```

When an assertion first runs, a snapshot is automatically recorded to disk and the test will fail, printing out the file path of any newly-recorded reference.

> 🛑 failed - Recorded: …
>
> "…/MyAppTests/\_\_Snapshots\_\_/MyViewControllerTests/testMyViewController.png"

Repeat test runs will load this reference and compare it with the runtime value. If they don't match, the test will fail and describe the difference.

You can record a new reference by setting the `record` mode to `true` on the assertion or globally.

``` swift
assertSnapshot(matching: vc, as: .image, record: true)

// or globally

record = true
assertSnapshot(matching: vc, as: .image)
```

## Snapshot Anything

While most snapshot testing libraries in the Swift community are limited to `UIView`s and `UIImage`s, SnapshotTesting can work with _any_ value and _any_ format on _any_ Swift platform!

The `assertSnapshot` function accepts a value and any snapshot strategy that value supports. This means that a [view](Documentation/Available-Snapshot-Strategies.md#uiview) or [view controller](Documentation/Available-Snapshot-Strategies.md#uiviewcontroller) can be tested against an image representation _and_ against a textual representation of its properties and subview hierarchy.

``` swift
assertSnapshot(matching: vc, as: .image)
assertSnapshot(matching: vc, as: .recursiveDescription)
```

View testing is [highly configurable](Documentation/Available-Snapshot-Strategies.md#uiviewcontroller). You can override trait collections (for specific size classes and content size categories) and generate device-agnostic snapshots, all from a single simulator.

``` swift
assertSnapshot(matching: vc, as: .image(on: .iPhoneSe))
assertSnapshot(matching: vc, as: .image(on: .iPhoneSe(.landscape)))
assertSnapshot(matching: vc, as: .image(on: .iPhoneX))
assertSnapshot(matching: vc, as: .image(on: .iPadMini(.portrait)))
```

Better yet, SnapshotTesting isn't limited to views and view controllers! There are [a number of available snapshot strategies](Documentation/Available-Snapshot-Strategies.md) to choose from.

For example, you can snapshot test URL requests (_e.g._, those that your API client prepares).

``` swift
assertSnapshot(matching: urlRequest, as: .raw)
// POST http://localhost:8080/account
// Cookie: pf_session={"userId":"1"}
//
// email=blob%40pointfree.co&name=Blob
```

And you can snapshot test `Encodable` values against their JSON _and_ property list representations.

``` swift
assertSnapshot(matching: user, as: .json)
// {
//   "bio" : "Blobbed around the world.",
//   "id" : 1,
//   "name" : "Blobby"
// }

assertSnapshot(matching: user, as: .plist)
// <?xml version="1.0" encoding="UTF-8"?>
// <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
// <plist version="1.0">
// <dict>
//   <key>bio</key>
//   <string>Blobbed around the world.</string>
//   <key>id</key>
//   <integer>1</integer>
//   <key>name</key>
//   <string>Blobby</string>
// </dict>
// </plist>
```

In fact, _[any](Documentation/Available-Snapshot-Strategies.md#any)_ value can be snapshot-tested by default using its [mirror](https://developer.apple.com/documentation/swift/mirror)!

``` swift
assertSnapshot(matching: user, as: .dump)
// ▿ User
//   - bio: "Blobbed around the world."
//   - id: 1
//   - name: "Blobby"
```

If your data can be represented as an image, text, or data, you can write a snapshot test for it! Check out [all of the snapshot strategies](Documentation/Available-Snapshot-Strategies.md) that ship with SnapshotTesting and [learn how to define your own custom strategies](Documentation/Defining-Custom-Snapshot-Strategies.md).

## Installation

### Carthage

If you use [Carthage](https://github.com/Carthage/Carthage), you can add the following dependency to your `Cartfile`:

``` ruby
github "pointfreeco/swift-snapshot-testing" ~> 1.0
```

### CocoaPods

If your project uses [CocoaPods](https://cocoapods.org), add the pod to any applicable test targets in your `Podfile`:

```ruby
target 'MyAppTests' do
  pod 'SnapshotTesting', '~> 1.0'
end
```

### Swift Package Manager

If you want to use SnapshotTesting in a project that uses [SwiftPM](https://swift.org/package-manager/), add the package as a dependency in `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.0.0"),
]
```

## Features

  - [**Dozens of snapshot strategies**](Documentation/Available-Snapshot-Strategies.md). Snapshot testing isn't just for `UIView`s and `CALayer`s. Write snapshots against _any_ value.
  - [**Write your own snapshot strategies**](Documentation/Defining-Custom-Snapshot-Strategies.md). If you can convert it to an image, string, data, or your own diffable format, you can snapshot test it! Build your own snapshot strategies from scratch or transform existing ones.
  - **No configuration required.** Don't fuss with scheme settings and environment variables. Snapshots are automatically saved alongside your tests.
  - **More hands-off.** New snapshots are recorded whether `record` mode is `true` or not.
  - **Subclass-free.** Assert from any XCTest case or Quick spec.
  - **Device-agnostic snapshots.** Render views and view controllers for specific devices and trait collections from a single simulator.
  - **First-class Xcode support.** Image differences are captured as XCTest attachments. Text differences are rendered in inline error messages.
  - **Supports any platform that supports Swift.** Write snapshot tests for iOS, Linux, macOS, and tvOS.
  - **SceneKit, SpriteKit, and WebKit support.** Most snapshot testing libraries don't support these view subclasses.
  - **`Codable` support**. Snapshot encodable data structures into their [JSON](Documentation/Available-Snapshot-Strategies.md#json) and [property list](Documentation/Available-Snapshot-Strategies.md#plist) representations.
  - **Custom diff tool integration**.
  
## Related Tools

  - [`iOSSnapshotTestCase`](https://github.com/uber/ios-snapshot-test-case/) helped introduce screen shot testing to a broad audience in the iOS community. Experience with it inspired the creation of this library.

  - [Jest](https://jestjs.io) brought generalized snapshot testing to the front-end with a polished user experience. Several features of this library (diffing, automatically capturing new snapshots) were directly influenced.

## Learn More

SnapshotTesting was designed with [witness-oriented programming](https://www.pointfree.co/episodes/ep39-witness-oriented-library-design).

This concept (and more) are explored thoroughly in a series of episodes on [Point-Free](https://www.pointfree.co), a video series exploring functional programming and Swift hosted by [Brandon Williams](https://github.com/mbrandonw) and [Stephen Celis](https://github.com/stephencelis).

Witness-oriented programming was explored in the following episodes:

  - [Episode 33](https://www.pointfree.co/episodes/ep33-protocol-witnesses-part-1): Protocol Witnesses: Part 1
  - [Episode 34](https://www.pointfree.co/episodes/ep34-protocol-witnesses-part-1): Protocol Witnesses: Part 2
  - [Episode 35](https://www.pointfree.co/episodes/ep35-advanced-protocol-witnesses-part-1): Advanced Protocol Witnesses: Part 1
  - [Episode 36](https://www.pointfree.co/episodes/ep36-advanced-protocol-witnesses-part-2): Advanced Protocol Witnesses: Part 2
  - [Episode 37](https://www.pointfree.co/episodes/ep37-protocol-oriented-library-design-part-1): Protocol-Oriented Library Design: Part 1
  - [Episode 38](https://www.pointfree.co/episodes/ep38-protocol-oriented-library-design-part-2): Protocol-Oriented Library Design: Part 2
  - [Episode 39](https://www.pointfree.co/episodes/ep39-witness-oriented-library-design): Witness-Oriented Library Design

<a href="https://www.pointfree.co/episodes/ep26-domain-specific-languages-part-1">
  <img alt="video poster image" src="https://d1hf1soyumxcgv.cloudfront.net/0039-witness-oriented-library-design/poster.jpg" width="480">
</a>

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
