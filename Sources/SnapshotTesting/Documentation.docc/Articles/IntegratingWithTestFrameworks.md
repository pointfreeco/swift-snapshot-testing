# Integrating with test frameworks

Learn how to use snapshot testing in the two main testing frameworks: Xcode's XCTest and Swift's
native testing framework.

## Overview

The Apple ecosystem currently has two primary testing frameworks, and unfortunately they are not
compatible with each other. There is the XCTest framework, which is a private framework provided
by Apple and heavily integrated into Xcode. And now there is Swift Testing, an open source testing
framework built in Swift that is capable of integrating into a variety of environments.

These two frameworks are not compatible in the sense that an assertion made in one framework
from a test in the other framework will not trigger a test failure. So, if you are writing a test
with the new `@Test` macro style, and you use a test helper that ultimately calls `XCTFail` under
the hood, that will not bubble up to an actual test failure when tests are run. And similarly, if
you have a test case inheriting from `XCTestCase` that ultimiately invokes the new style `#expect`
macro, that too will not actually trigger a test failure.

However, these details have all been hidden away in the SnapshotTesting library. You can simply
use ``assertSnapshot(of:as:named:record:timeout:file:testName:line:)`` in either an `XCTestCase`
subclass _or_ `@Test`, and it will dynamically detect what context it is running in and trigger
the correct test failure:

```swift
@Test 
func testFeature() {
  assertSnapshot(of: MyView(), as: .image)  // ✅
}

class FeatureTests: XCTestCase {
  func testFeature() {
    assertSnapshot(of: MyView(), as: .image)  // ✅
  }
}
```

### Configuring snapshots

For the most part, asserting on snapshots works the same whether you are using XCTest or Swift
Testing. There is one major difference, and that is how snapshot configuration works. There are
two major ways snapshots can be configured: ``SnapshotTestingConfiguration/diffTool-swift.property``
and ``SnapshotTestingConfiguration/record-swift.property``. 

The `diffTool` property allows you to customize how a command is printed to the test failure
message that allows you to quickly open a diff of two files, such as
[Kaleidoscope](http://kaleidoscope.app). The `record` property allows you to change the mode of
assertion so that new snapshots are generated and saved to disk.

These properties can be overridden for a scope of an operation using the
``withSnapshotTesting(record:diffTool:operation:)-2kuyr`` function. In a Swift Testing context 
you can apply the ``Testing/Trait/snapshots`` trait to either a single test or an entire suite: 

```swift
import SnapshotTesting

@Suite(.snapshots(record: .failed, diffTool: .ksdiff))
struct FeatureTests {
  …
}
```

This will override the `diffTool` and `record` properties for each test in the suite.

In an XCTest context, the simplest way to do this is to override the `invokeTest` method on 
`XCTestCase` and wrap it in `withSnapshotTesting`:

```swift
class FeatureTests: XCTestCase {
  override func invokeTest() {
    withSnapshotTesting(record: .failed, diffTool: .ksdiff) {
      super.invokeTest()
    }
  }
}
```

This will override the `diffTool` and `record` properties for each test function.

### UI Testing

Xcode's UI testing tools are currently incompatible with Swift Testing. Simply adding
`import Testing` to any UI test target file will cause a compilation error saying that "Testing"
cannot be found. This complicates using SnapshotTesting in UI test targets because it needs to
import Testing in order to provide the test helpers mentioned above.

The way in which Xcode disallows importing Testing in UI test targets is via the presence of a 
special Swift flag:

```
-module_alias Testing=_Testing_Unavailable
```

This is done so that people do not expect `#expect` and other Testing tools to work in UI test 
targets. If you want to use SnapshotTesting in a UI test target, we recommend that you remove
this flag:

  * Open your project's settings and navigate to the settings for your UI testing target.
  * Search for "Other Swift flags" in the "Build Settings" tab.
  * Delete the `$(inherited)` flag.

Now you can `import SnapshotTesting` in UI test targets _and_ make use of `assertSnapshot`. But
do remember that you _cannot_ use `#expect` or any of the other tools from Swift Testing.
