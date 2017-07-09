# swift-snapshot-testing [![CircleCI](https://circleci.com/gh/pointfreeco/swift-snapshot-testing.svg?style=svg)](https://circleci.com/gh/pointfreeco/swift-snapshot-testing)

Tests that save and assert against reference data.

## Stability

This library should be considered alpha, and not stable. Breaking changes will happen often.

## Installation

```swift
import PackageDescription

let package = Package(
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", .branch("master")),
  ]
)
```

## Usage

```swift
import SnapshotTesting
import XCTest

class MyViewControllerTest: XCTestCase {
  func testMyViewController() {
    let vc = MyViewController()
    assertSnapshot(matches: vc)
  }
}
```

The `assertSnapshot(matches:)` function can be called with any type conforming to the `Snapshot` protocol. Out of the box, this includes:

- `Cocoa.NSImage`
- `Cocoa.NSView`
- `Cocoa.NSViewController`
- `Foundation.Data`
- `Foundation.String`
- `QuartzCore.CALayer`
- `UIKit.UIImage`
- `UIKit.UIView`
- `UIKit.UIViewController`

### `Encodable` support

The `assertSnapshot(encoding:)` function can be called with any type conforming to the `Encodable` protocol.

``` swift
import SnapshotTesting
import XCTest

struct User: Encodable {
  let id: Int
  let name: String
}

class UserTest: XCTestCase {
  func testUser() {
    let user = User(id: 1, name: "Blob")
    assertSnapshot(encoding: user)
  }
}
```
