# Swift Testing attachment support

Learn how snapshot test failures automatically attach reference images, actual results, and diffs to your test results when using Swift Testing.

## Overview

Starting with Swift 6.2 and Xcode 26, swift-snapshot-testing now supports attachments when running tests with Swift Testing. When a snapshot test fails, the library automatically attaches the reference image, actual result, and a visual diff directly to your test results in Xcode, making it easier to diagnose and fix test failures.

## Requirements

- **Swift 6.2** or later
- **Xcode 26** or later
- Tests must be run using Swift Testing (not XCTest)

## How it works

When a snapshot test fails under Swift Testing:

### Image snapshots

Three attachments are created:
- **reference**: The expected image
- **failure**: The actual image that was captured
- **difference**: A visual diff highlighting the differences

### Text snapshots

One attachment is created:
- **difference.patch**: A unified diff showing the textual changes

## Implementation details

The implementation recreates attachment data from the original source values:
- `XCTAttachment` doesn't expose its internal data (userInfo is always nil), so we recreate it from the snapshot's reference and diffable values
- For image attachments, we call `snapshotting.diffing.toData()` on the reference/failure values
- For difference images, we regenerate the visual diff using the internal `diff()` functions
- When running under XCTest, it uses the traditional `XCTAttachment` approach
- This ensures backward compatibility while adding Swift Testing support

## Viewing Attachments

### In Xcode
- Attachments appear in the test navigator next to failed tests
- Click on an attachment to preview it inline
- Right-click to export or open in an external viewer

### In CI/Command Line
- Attachments are saved to the `.xcresult` bundle
- Extract with: `xcrun xcresulttool get --path Test.xcresult --id <attachment-id>`
- Or open the `.xcresult` file directly in Xcode

## Example usage

```swift
import Testing
import SnapshotTesting

@Test func testUserProfile() {
    let view = UserProfileView(name: "Alice")

    // If this fails, three attachments will be automatically created
    assertSnapshot(of: view, as: .image)
}
```

## Backward compatibility

- Code using XCTest continues to work unchanged
- Swift versions before 6.2 will use XCTAttachment (no Swift Testing attachments)
- The feature is conditionally compiled based on Swift version

## Notes

- Attachments are non-copyable and can only be attached once per test.
- The attachment system respects the test's source location for better debugging.
- Empty images and corrupted data are handled gracefully.