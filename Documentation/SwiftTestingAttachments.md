# Swift Testing Attachment Support

## Overview

Starting with Swift 6.2 / Xcode 26, swift-snapshot-testing now supports attachments when running tests with Swift Testing. This means snapshot failures will automatically attach reference images, actual results, and diffs directly to your test results in Xcode.

## Requirements

- **Swift 6.2** or later
- **Xcode 26** or later
- Tests must be run using Swift Testing (not XCTest)

## How It Works

When a snapshot test fails under Swift Testing:

### For Image Snapshots
Three attachments are created:
1. **reference** - The expected image
2. **failure** - The actual image that was captured
3. **difference** - A visual diff showing the differences

### For String/Text Snapshots
One attachment is created:
- **difference.patch** - A unified diff showing the changes

## Implementation Details

The implementation uses a dual-attachment system:
- `DualAttachment` stores both the raw data and an `XCTAttachment`
- When running under Swift Testing, it calls `Attachment.record()` with the raw data
- When running under XCTest, it uses the traditional `XCTAttachment` approach
- This ensures backward compatibility while adding new functionality

## Viewing Attachments

### In Xcode
- Attachments appear in the test navigator next to failed tests
- Click on an attachment to preview it inline
- Right-click to export or open in an external viewer

### In CI/Command Line
- Attachments are saved to the `.xcresult` bundle
- Extract with: `xcrun xcresulttool get --path Test.xcresult --id <attachment-id>`
- Or open the `.xcresult` file directly in Xcode

## Performance Considerations

- Large images (>10MB) are automatically compressed using JPEG to reduce storage
- Attachments are only created on test failure (not on success)
- Thread-safe storage ensures no race conditions in parallel test execution

## Example Usage

```swift
import Testing
import SnapshotTesting

@Test func testUserProfile() {
    let view = UserProfileView(name: "Alice")

    // If this fails, three attachments will be automatically created
    assertSnapshot(of: view, as: .image)
}
```

## Backward Compatibility

- Code using XCTest continues to work unchanged
- Swift versions before 6.2 will use XCTAttachment (no Swift Testing attachments)
- The feature is conditionally compiled based on Swift version

## Notes

- Attachments are non-copyable and can only be attached once per test
- The attachment system respects the test's source location for better debugging
- Empty images and corrupted data are handled gracefully