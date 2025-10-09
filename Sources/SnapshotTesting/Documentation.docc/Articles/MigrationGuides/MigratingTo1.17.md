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
    diffs of files, but only works when the command line tool accepts a very narrow set of 
    arguments,  _e.g.:

    ```sh
    ksdiff /path/to/file1.png /path/to/file2.png
    ```

Because of these reasons, the globals ``isRecording`` and ``diffTool`` are now deprecated, and we
have introduced a new tool that greatly improves upon all of these problems. There is now a function
called ``withSnapshotTesting(record:diffTool:operation:)-2kuyr`` for customizing snapshots. It 
allows you to customize how the `assertSnapshot` tool behaves for a well-defined scope.

Rather than overriding `isRecording` or `diffTool` directly in your tests, you can wrap your test in
`withSnapshotTesting`:

@Row {
  @Column {
    ```swift
    // Before

    func testFeature() {
      isRecording = true 
      diffTool = "ksdiff"
      assertSnapshot(…)
    }
    ```
  }
  @Column {
    ```swift
    // After

    func testFeature() {
      withSnapshotTesting(record: .all, diffTool: .ksdiff) {
        assertSnapshot(…)
      }
    }
    ```
  }
}

If you want to override the options for an entire test class, you can override the `invokeTest`
method of `XCTestCase`:

@Row {
  @Column {
    ```swift
    // Before

    class FeatureTests: XCTestCase {
      override func invokeTest() {
        isRecording = true 
        diffTool = "ksdiff"
        defer { 
          isRecording = false
          diffTool = nil
        }
        super.invokeTest()
      }
    }
    ```
  }
  @Column {
    ```swift
    // After

    class FeatureTests: XCTestCase {
      override func invokeTest() {
        withSnapshotTesting(record: .all, diffTool: .ksdiff) {
          super.invokeTest()
        }
      }
    }
    ```
  }
}

And if you want to override these settings for _all_ tests, then you can implement a base
`XCTestCase` subclass and have your tests inherit from it.

Further, the `diffTool` and `record` arguments have extra customization capabilities:

  * `diffTool` is now a [function](<doc:SnapshotTestingConfiguration/DiffTool-swift.struct>) 
    `(String, String) -> String` that is handed the current snapshot file and the failed snapshot
    file. It can return the command that one can run to display a diff. For example, to use
    ImageMagick's `compare` command and open the result in Preview.app:

    ```swift
    extension SnapshotTestingConfiguration.DiffTool {
      static let compare = Self { 
        "compare \"\($0)\" \"\($1)\" png: | open -f -a Preview.app" 
      }
    }
    ```

  * `record` is now a [type](<doc:SnapshotTestingConfiguration/Record-swift.struct>) with 4
    choices: `all`, `missing`, `never`, `failed`:
    * `all`: All snapshots will be generated and saved to disk. 
    * `missing`: only the snapshots that are missing from the disk will be generated
    and saved. 
    * `never`: No snapshots will be generated, even if they are missing. This option is appropriate
    when running tests on CI so that re-tries of tests do not surprisingly pass after snapshots are
    unexpectedly generated.
    * `failed`: Snapshots only for failing tests will be generated. This can be useful for tests
    that use precision thresholds so that passing tests do not re-record snapshots that are 
    subtly different but still within the threshold.

## Beta support for Swift Testing

This release of the library provides beta support for Swift's native Testing library. Prior to this
release, using `assertSnapshot` in a `@Test` would result in a passing test no matter what. That is
because under the hood `assertSnapshot` uses `XCTFail` to trigger test failures, but that does not
cause test failures when using Swift Testing.

In version 1.17 the `assertSnapshot` helper will now intelligently figure out if tests are running
in an XCTest context or a Swift Testing context, and will determine if it should invoke `XCTFail` or
`Issue.record` to trigger a test failure.

For the most part you can write tests for Swift Testing exactly as you would for XCTest. However,
there is one major difference. In order to override a snapshot's 
[configuration](<doc:SnapshotTestingConfiguration>) for a particular test or an entire suite you
must use what are known as "test traits":

```swift
import SnapshotTesting

@Suite(.snapshots(record: .all, diffTool: .ksdiff))
struct FeatureTests {
  …
}
```

That will override the `diffTool` and `record` options for the entire `FeatureTests` suite.
These traits can also be used on individual `@Test`s too.
