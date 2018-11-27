# swift-snapshot-testing

macOS [![CircleCI](https://circleci.com/gh/pointfreeco/swift-snapshot-testing.svg?style=svg)](https://circleci.com/gh/pointfreeco/swift-snapshot-testing) Linux [![Build Status](https://travis-ci.org/pointfreeco/swift-snapshot-testing.svg)](https://travis-ci.org/pointfreeco/swift-snapshot-testing)

Automatically record app data into test assertions. Snapshot tests capture the entirety of a data structure and cover far more surface area than a typical unit test.

![An example of a snapshot failure in Xcode.](.github/snapshot-test-1.png)

# Contents

* [Features](#features)
* [Usage](#usage)
  * [Basics](#basics)
  * Custom snapshot strategies
  * [Advanced](#advanced)
* [Installation](#installation)
  * Swift Package Manager
  * [Cocoapods](#cocoapods)
  * [Carthage](#carthage)
  * Git Submodule
* Related Tools
* Learn More
* [License](#license)

---

## Features

- **Snapshot test _anything_.** Snapshot testing isn’t just for UI. Write snapshots against any format!
- **No configuration required.** Don’t fuss with scheme settings and environment variables. Snapshots are automatically saved alongside your tests.
- **More hands-off.** New snapshots are automatically recorded.
- **Subclass-free.** Assert from any XCTest test case or Quick spec.
- **Device-agnostic snapshots.** Render views and view controllers for specific devices and trait collections from a single simulator.
- **iOS, macOS, and tvOS support.**
- **SceneKit, SpriteKit, and WebKit support.**
- **Test _any_ data structure.** Snap complex app state in a dependable way.
- **Codable support**. Snapshot your data structures into JSON and property lists.
- **Extensible and transformable.** Build your own snapshot strategies from scratch or build from existing ones.

## Usage

Snapshot Testing provides an `assertSnapshot` function for asserting that the reference data on disk matches the current snapshot of your data. The reference data can be plain text, an image, or any other data format you may be interested in.

### Basics

Suppose you had an `ApiService` that creates properly formatted URL requests to your web API. It might be responsible for attaching authorization to the query params, setting some custom request headers, and more. You can write an assertion against the `URLRequest` that is constructed from your service to give broad test coverage across all the properties of the value:

```swift
import SnapshotTesting
import XCTest
 
class ApiServiceTests: XCTestCase {
  func testUrlRequestPreparation() {
    let service = ApiService()
    let request = service
      .prepare(endpoint: .createArticle("Hello, world!"))
 
    assertSnapshot(matching: request)
  }
}
```

The first time this is run, a file will be written to `__Snapshots__/ApiServiceTests/testUrlRequestPreparation.0.txt`:

```txt
POST https://api.site.com/articles?oauth_token=deadbeef
User-Agent: iOS/BlobApp 1.0
X-App-Version: 42

title=Hello%20World
```

Subsequent test runs will generate a new snapshot and assert it against the contents of this file on disk. If there are any differences, the test will fail and present a nicely formatted diff. For example, suppose that during a refactor we accidentally broke the logic that sets the HTTP method of the request. This would easily be caught in our snapshot:

```diff
-POST https://api.site.com/articles?oauth_token=deadbeef
+GET https://api.site.com/articles?oauth_token=deadbeef
User-Agent: iOS/BlobApp 1.0
X-App-Version: 42

title=Hello%20World
```

### Snapshot strategies

The `assertSnapshot` helper allows you to customize how you want to snapshot your values by providing a `Strategy`. It is a concrete datatype that describes preicsely how to snapshot a value, including how to serialize/deserialize to/from disk, and how to display a human friendly description of a diff. Snapshot Testing comes with many strategies for snapshotting a wide assortment of Foundation, UIKit and Cocoa types in both text and image formats.

For example, a `UIView` could be snapshot as an image:

```swift
let myView = ...
assertSnapshot(myView, as: .image)
```

But it could also be snapshot as a textual description of the view tree hierarchy:

```swift
let myView = ...
assertSnapshot(myView, as: .recursiveDescription)
```

Note that we can use the abbreviated `.image` and `.recursiveDescription` syntax because `image` is a static property on `Strategy`.



### Custom snapshot strategies

Although the library comes with [many](link) snapshot strategies for various types in Foundation, UIKit and Cocoa, there are still going to be times you want to customize a snapshot's output. For those times, you want to create a custom `Strategy` value that can be passed to the `assertSnapshot` helper.

todo: pullback

### Advanced

Some types need additional set up time in order to be snapshot. For example, `WKWebView` needs to wait for a delegate callback that says the view is finished loading before it can be snapshot. For this reason, `Strategy` does not use a function of the form `(Snapshottable) -> Format` to snapshot types, but rather a function `(Snapshottable) -> Async<Format>`, where `Async` is a wrapper around a callback. This allows you to take as much time as you need to perform the snapshot.

For example, to snapshot a `WKWebView` you must wait until the delegate calls `webView(_:didFinish:)`. This can handily be done using `Async`:

```swift
private final class NavigationDelegate: NSObject, WKNavigationDelegate {
  var didFinish: () -> Void = { }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    self.didFinish()
  }
}

let webViewImage = Strategy<WKWebView, UIImage>(
  pathExtension: "png",
  diffable: .image,
  snapshotToDiffable: { webView in
    Async<UIImage> { callback in 
      let delegate = NavigationDelegate()
      delegate.didFinish = {
        webView.takeSnapshot(with: nil) { image, _ in 
          callback(image!)
        }
      }
      webView.navigationDelegate = delegate
    }
  }
)
```

## Installation

### Swift Package Manager

```swift
import PackageDescription

let package = Package(
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", .branch("master")),
  ]
)
```

### Cocoapods

```ruby
target 'Tests' do
  pod 'SnapshotTesting', :git => 'https://github.com/pointfreeco/swift-snapshot-testing.git'
end
```

## Related Tools

- [`FBSnapshotTestCase`](https://github.com/facebook/ios-snapshot-test-case) helped introduce screen shot testing to a broad audience in the iOS community. Experience with it inspired the creation of this library.

- [`Jest`](http://facebook.github.io/jest/) brought generalized snapshot testing to the front-end with a polished user experience. Several features of this library (diffing, tracking outdated snapshots) were directly influenced.

## Learn More

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.














































---

# swift-snapshot-testing

macOS [![CircleCI](https://circleci.com/gh/pointfreeco/swift-snapshot-testing.svg?style=svg)](https://circleci.com/gh/pointfreeco/swift-snapshot-testing) Linux [![Build Status](https://travis-ci.org/pointfreeco/swift-snapshot-testing.svg)](https://travis-ci.org/pointfreeco/swift-snapshot-testing)

Automatically record app data into test assertions. Snapshot tests capture the entirety of a data structure and cover far more surface area than a typical unit test.

The design of this library has been covered in "[Snapshot Testing in Swift](http://www.stephencelis.com/2017/09/snapshot-testing-in-swift)".

![An example of a snapshot failure in Xcode.](.github/snapshot-test.png)

## Stability

This library should be considered alpha, and not stable. Breaking changes will happen often.

## Installation

### Swift Package Manager

```swift
import PackageDescription

let package = Package(
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", .branch("master")),
  ]
)
```

### Cocoapods

```ruby
target 'Tests' do
  pod 'SnapshotTesting', :git => 'https://github.com/pointfreeco/swift-snapshot-testing.git'
end
```

## Usage

Snapshot Testing provides an `assertSnapshot` function, which records data structures as text or images accordingly.

Here's how you might test a URL request you've prepared for your app's API client:

```swift
import SnapshotTesting
import XCTest

class ApiServiceTests: XCTestCase {
  func testUrlRequestPreparation() {
    let service = ApiService()
    let request = service
      .prepare(endpoint: .createArticle("Hello, world!"))

    assertSnapshot(matching: request)
  }
}
```

The above will render as the following text to `__Snapshots__/ApiServiceTests/testUrlRequestPreparation.0.txt`:

```
▿ https://api.site.com/articles?oauth_token=deadbeef
  ▿ url: Optional(https://api.site.com/articles?oauth_token=deadbeef)
    ▿ some: https://api.site.com/articles?oauth_token=deadbeef
      - _url: https://api.site.com/articles?oauth_token=deadbeef #0
        - super: NSObject
  - cachePolicy: 0
  - timeoutInterval: 60.0
  - mainDocumentURL: nil
  - networkServiceType: __ObjC.NSURLRequest.NetworkServiceType
  - allowsCellularAccess: true
  ▿ httpMethod: Optional("POST")
    - some: "POST"
  ▿ allHTTPHeaderFields: Optional(["App-Version": "42"])
    ▿ some: 1 key/value pairs
      ▿ (2 elements)
        - key: "App-Version"
        - value: "42"
  ▿ httpBody: Optional(19 bytes)
    ▿ some: "body=Hello%20world!"
  - httpBodyStream: nil
  - httpShouldHandleCookies: true
  - httpShouldUsePipelining: false
```

Renderable data will write as an image. This includes `UIImage`s and `NSImage`s, but also data that is typically viewed visually, like `UIView`s and `NSView`s.

Given a view:

``` swift
import SnapshotTesting
import XCTest

class HomepageTests: XCTestCase {
  func testRender() {
    let size = CGSize(width: 800, height: 600)
    let webView = UIWebView(frame: .init(origin: .zero, size: size))
    webView.loadHTMLString(renderHomepage())

    assertSnapshot(matching: webView)
  }
}
```

The above will write to an image on disk. If that image ever renders differently in the future, the assertion will fail and produce a diff for inspection.

![A screen shot failure.](.github/kaleidoscope-diff.png)


## Related Tools

  - [`FBSnapshotTestCase`](https://github.com/facebook/ios-snapshot-test-case) helped introduce screen shot testing to a broad audience in the iOS community. Experience with it inspired the creation of this library.

  - [`Jest`](http://facebook.github.io/jest/) brought generalized snapshot testing to the front-end with a polished user experience. Several features of this library (diffing, tracking outdated snapshots) were directly influenced.


## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
