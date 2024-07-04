# Migrating to 1.17

Learn how to use the new `withSnapshotTesting` tool for customizing how snapshots are generated and
diffs displayed.

## Overview

This library is under constant development, and we are always looking for ways to simplify the 
library, and make it more powerful. This version of the library has deprecated some APIs,
introduced a new APIs, and includes beta support for Swift's new native testing library.  

## Customizing snapshots

Currently there are two global variables in the library for customizing snapshot testing:

  * ``isRecording`` determines whether new snapshots are generated and saved to disk when the test
    runs.

  * ``diffTool`` determines the command line tool that is used to inspect the diff of two files on
    disk.

These customization options have a few downsides currently. 

  * First, because they are globals they can easily bleed over from test to test in unexpected ways.
    And further, Swift's new testing library runs parallel tests in the same process, which is in
    stark contrast to XCTest, which runs parallel tests in separate processes. This means there are
    even more chances for these globals to bleed from one test to another.

  * And second, these options aren't as granular as some of our users wanted. When ``isRecording``
    is true snapshots are generated and written to disk, and when it is false snapshots are not 
    generated, _unless_ a file is not present on disk. The a snapshot _is_ generated. Some of our
    users wanted an option between these two extremes, where snapshots would not be generated if the
    file does not exist on disk.

And the ``diffTool`` variable allows one to specify a command line tool to use for visualizing
diffs of files, but only works when the command line tool accepts a very narrow set of arguments, 
_e.g._ `ksdiff /path/to/file1.png /path/to/file2.png`.

We have greatly improved upon all of these problems by introducing the new 
``withSnapshotTesting(record:diffTool:operation:)-59u9g`` tool for customizing snapshots. It 
allows you to customize how the `assertSnapshot` tool behaves for a well-defined scope.

Rather than overriding `isRecording` or `diffTool` directly in your tests, you can wrap your test in
`withSnapshotTesting`:

```swift
withSnapshotTesting(diffTool: .ksdiff, record: .all) {
  // Assertions in here
}
```

If you want to override the options for an entire test class, you can override the `invokeTest`
method of `XCTestCase`:

```swift
class FeatureTests: XCTestCase {
  override func invokeTest() {
    withSnapshotTesting(diffTool: .ksdiff, record: .all) {
      super.invokeTest()
    }
  }
}
```

And if you want to override these settings for _all_ tests, then you can implement a base
`XCTestCase` subclass and have your tests inherit from it.

Further, the `diffTool` and `record` arguments have extra customization capabilities:

  * `diffTool` is now a [function](<doc:SnapshotTestingConfiguration/DiffTool-swift.struct>) 
    `(String, String) -> String` that is handed the current snapshot file and the failed snapshot
    file. It can return the command that one can run to display a diff:

  ```swift
  extension SnapshotTestingConfiguration.DiffTool {
    static let compare = Self { 
      "compare \"\($0.path)\" \"\($1.path)\" png: | open -f -a Preview.app" 
    }
  }
  ```

  * `record` is now an [enum](<doc:SnapshotTestingConfiguration/Record-swift.enum>) with 3
    choices: `all`, `missing`, `none`. When set to `all`, snapshots will be generated and saved to 
    disk. When set to `missing` only the snapshots that are missing from the disk will be generated
    and saved. And when set to `none` snapshots will never be generated, even if they are missing.
    This option is appropriate when running tests on CI so that re-tries of tests do not
    surprisingly pass after snapshots are unexpectedly generated.

## Beta support for Swift Testing

This release of the library provides beta support for Swift's native Testing library. Prior to this
release, using `assertSnapshot` in a `@Test` would result in a passing test no matter what. That is
because under the hood `assertSnapshot` uses `XCTFail` to trigger test failures, but that does not
cause test failures when using Swift Testing.

In version 1.17 the `assertSnapshot` helper will now intelligently figure out if tests are running
in an XCTest context or a Swift Testing context, and will determine if it should invoke `XCTFail` or
`Issue.record` to trigger a test failure.

For the most part you can write tests for Swift Testing exactly as you would for XCTest. However,
there is one major difference. Swift Testing does not (yet) have a substitute for `invokeTest`,
which we used alongside `withSnapshotTesting` to customize snapshotting for a full test class.

There is an experimental version of this tool in Swift Testing, called `CustomExecutionTrait`, and
this library provides such a trait called ``Testing/Trait/snapshots(diffTool:record:)``. It allows 
you to customize snapshots for a `@Test` or `@Suite`, but to get access to it you must perform an
`@_spi(Experimental)` import of snapshot testing:

```swift
@_spi(Experimental) import SnapshotTesting

@Suite(.snapshots(diffTool: .ksdiff, record: .all))
struct FeatureTests {
  …
}
```

That will override the `diffTool` and `record` options for the entire `FeatureTests` suite.
