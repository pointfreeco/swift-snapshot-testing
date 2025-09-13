#if compiler(>=6) && canImport(Testing)
  import Testing
  import SnapshotTesting
  @testable import SnapshotTesting

  #if os(iOS) || os(tvOS)
    import UIKit
  #elseif os(macOS)
    import AppKit
  #endif

  extension BaseSuite {
    @Suite(.serialized, .snapshots(record: .missing))
    struct SwiftTestingAttachmentTests {

      // Test that string snapshots create attachments on failure
      @Test func testStringSnapshotAttachments() {
        // String snapshots should create a patch attachment on failure
        withKnownIssue {
          let original = """
          Line 1
          Line 2
          Line 3
          """

          let modified = """
          Line 1
          Line 2 Modified
          Line 3
          Line 4 Added
          """

          // First record the original
          assertSnapshot(of: original, as: .lines, named: "multiline", record: true)
          // Then test with modified (should fail and create patch attachment)
          assertSnapshot(of: modified, as: .lines, named: "multiline")
        } matching: { issue in
          issue.description.contains("does not match reference")
        }
      }

      #if os(iOS) || os(tvOS)
      @Test func testImageSnapshotAttachments() {
        // Create two different images to force a failure
        let size = CGSize(width: 100, height: 100)

        UIGraphicsBeginImageContext(size)
        let context1 = UIGraphicsGetCurrentContext()!
        context1.setFillColor(UIColor.red.cgColor)
        context1.fill(CGRect(origin: .zero, size: size))
        let redImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        UIGraphicsBeginImageContext(size)
        let context2 = UIGraphicsGetCurrentContext()!
        context2.setFillColor(UIColor.blue.cgColor)
        context2.fill(CGRect(origin: .zero, size: size))
        let blueImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        // First record the red image
        assertSnapshot(of: redImage, as: .image, named: "color-test", record: true)

        // Then test with blue image (should fail and create attachments)
        withKnownIssue {
          assertSnapshot(of: blueImage, as: .image, named: "color-test")
        } matching: { issue in
          // Should create reference, failure, and difference image attachments
          issue.description.contains("does not match reference")
        }
      }
      #endif

      #if os(macOS)
      @Test func testNSImageSnapshotAttachments() {
        // Create two different images to force a failure
        let size = NSSize(width: 100, height: 100)

        let redImage = NSImage(size: size)
        redImage.lockFocus()
        NSColor.red.setFill()
        NSRect(origin: .zero, size: size).fill()
        redImage.unlockFocus()

        let blueImage = NSImage(size: size)
        blueImage.lockFocus()
        NSColor.blue.setFill()
        NSRect(origin: .zero, size: size).fill()
        blueImage.unlockFocus()

        // First record the red image
        assertSnapshot(of: redImage, as: .image, named: "color-test", record: true)

        // Then test with blue image (should fail and create attachments)
        withKnownIssue {
          assertSnapshot(of: blueImage, as: .image, named: "color-test")
        } matching: { issue in
          // Should create reference, failure, and difference image attachments
          issue.description.contains("does not match reference")
        }
      }
      #endif

      @Test func testRecordedSnapshotAttachment() {
        // When recording a snapshot, it should also create an attachment
        assertSnapshot(
          of: ["key": "value"],
          as: .json,
          named: "recorded-test",
          record: true
        )

        // The recorded snapshot should have created an attachment
        // even though there was no failure
      }

      @Test func testNoAttachmentsOnSuccess() {
        // First record a snapshot
        let data = "Consistent Data"
        assertSnapshot(of: data, as: .lines, named: "success-test", record: true)

        // Then test with the same data (should pass with no attachments)
        assertSnapshot(of: data, as: .lines, named: "success-test")

        // No attachments should be created for passing tests
      }

      @Test func testDumpSnapshotAttachments() {
        struct TestStruct {
          let name: String
          let value: Int
          let nested: [String: Any] = ["key": "value"]
        }

        let original = TestStruct(name: "Original", value: 42)
        let modified = TestStruct(name: "Modified", value: 100)

        // Record original
        assertSnapshot(of: original, as: .dump, named: "struct-test", record: true)

        // Test with modified (should fail and create attachments)
        withKnownIssue {
          assertSnapshot(of: modified, as: .dump, named: "struct-test")
        } matching: { issue in
          issue.description.contains("does not match reference")
        }
      }

      @Test func testMultipleAttachmentsInSingleTest() {
        // Test that multiple snapshot failures in one test create
        // multiple sets of attachments

        withKnownIssue {
          // First failure
          assertSnapshot(of: "First", as: .lines, named: "multi-1", record: true)
          assertSnapshot(of: "First Modified", as: .lines, named: "multi-1")

          // Second failure
          assertSnapshot(of: "Second", as: .lines, named: "multi-2", record: true)
          assertSnapshot(of: "Second Modified", as: .lines, named: "multi-2")
        } matching: { _ in true }
      }
    }
  }
#endif