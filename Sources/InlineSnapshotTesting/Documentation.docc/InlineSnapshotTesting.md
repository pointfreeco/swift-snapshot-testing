# ``InlineSnapshotTesting``

Powerfully convenient snapshot testing.

## Overview

[Snapshot Testing][swift-snapshot-testing] writes the snapshots it generates directly to disk
alongside the test files. This makes for compact test cases with single line assertions...

```swift
assert(of: value, as: .json)
```

...but can make verification more cumbersome: one must find the corresponding file in order to
verify that it matches their expectation. In this case, if the above assertion is the second one in
a `testMySnapshot()` method in a `MySnapshotTests.swift` file, the snapshot will be found at:

```sh
$ cat __Snapshots__/MySnapshotTests/testMySnapshot.2.json
{
  "id": 42,
  "name": "Blob"
}
```

Inline Snapshot Testing offers an alternative approach by writing string snapshots directly into
the test file. This makes it easy to verify a snapshot test at any time, since the value and
snapshot sit next to each other in the assertion. One can `import InlineSnapshotTesting` and rewrite
the above assertion as:

```swift
assertInline(of: value, as: .json)
```

And when the test is run, it will automatically insert the snapshot as a trailing closure to be used
by future test runs, and fail:

```swift
assertInline(of: value, as: .json) {  // ❌
  """
  {
    "id": 42,
    "name": "Blob"
  }
  """
}
```

```
❌ failed - Automatically recorded a new snapshot.

Re-run "testMySnapshot" to test against the newly-recorded snapshot.
```

> Warning: When a snapshot is written into a test file, the undo history of the test file in Xcode
> will be lost. Be careful to avoid losing work, and commit often to version control.
>
> We would love for this to be fixed. Please [file feedback][apple-feedback] with Apple to improve
> things, or if you have an idea of how we can improve things from the library, please
> [start a discussion][discussions] or [open a pull request][pull-requests].

[apple-feedback]: https://www.apple.com/feedback/
[discussions]: https://github.com/pointfreeco/swift-composable-architecture/discussions
[pull-requests]: https://github.com/pointfreeco/swift-composable-architecture/pulls
[swift-snapshot-testing]: https://github.com/pointfreeco/swift-snapshot-testing

## Topics

### Essentials

- ``assertInline(of:as:message:record:timeout:serialization:closureDescriptor:matches:fileID:file:function:line:column:)-(_,SyncSnapshot<Input, Output>,_,_,_,_,_,_,_,_,_,_,_)``
- ``assertInline(of:as:message:record:timeout:serialization:closureDescriptor:matches:fileID:file:function:line:column:)-(_,AsyncSnapshot<Input, Output>,_,_,_,_,_,_,_,_,_,_,_)``
- ``assertInline(of:as:message:record:timeout:name:serialization:closureDescriptor:matches:fileID:file:function:line:column:)-(_,SyncSnapshot<Input, Output>,_,_,_,_,_,_,_,_,_,_,_,_)``
- ``assertInline(of:as:message:record:timeout:name:serialization:closureDescriptor:matches:fileID:file:function:line:column:)-(_,AsyncSnapshot<Input, Output>,_,_,_,_,_,_,_,_,_,_,_,_)``

### Writing a custom helper

- ``SnapshotClosureDescriptor``
