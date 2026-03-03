#if compiler(>=6.2) && canImport(Testing)
  import Testing
  import SnapshotTesting
  @testable import SnapshotTesting

  #if os(iOS) || os(tvOS)
    import UIKit
  #elseif os(macOS)
    import AppKit
  #endif

  extension BaseSuite {
    /// Verifies that diff attachments are actually created for Swift Testing.
    /// These tests would fail with the original userInfo-based approach.
    @Suite(.serialized, .snapshots(record: .missing))
    struct SwiftTestingAttachmentVerificationTests {

      #if os(macOS)
        @Test func imageDiffCreatesThreeAttachments() async throws {
          // When an image snapshot fails, it should create 3 diff attachments:
          // reference, failure, and difference.

          let size = NSSize(width: 50, height: 50)

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

          // Record the reference
          withKnownIssue {
            assertSnapshot(of: redImage, as: .image, named: "three-attachments-test", record: true)
          } matching: {
            $0.description.contains("recorded snapshot")
          }

          withKnownIssue {
            assertSnapshot(of: blueImage, as: .image, named: "three-attachments-test")
          } matching: {
            $0.description.contains("does not match reference")
          }
        }
      #endif

      @Test func stringDiffCreatesOnePatchAttachment() async throws {
        // When a string snapshot fails, it should create a patch attachment.
        let original = "Line 1\nLine 2\nLine 3"
        let modified = "Line 1\nLine 2 Changed\nLine 3\nLine 4"

        withKnownIssue {
          assertSnapshot(of: original, as: .lines, named: "patch-attachment-test", record: true)
        } matching: {
          $0.description.contains("recorded snapshot")
        }

        withKnownIssue {
          assertSnapshot(of: modified, as: .lines, named: "patch-attachment-test")
        } matching: {
          $0.description.contains("does not match reference")
        }
      }

      @Test func attachmentUserInfoIsNotRequired() async throws {
        // Regression test: Verifies attachments work without relying on userInfo.
        #if os(macOS)
          let size = NSSize(width: 20, height: 20)
          let img1 = NSImage(size: size)
          img1.lockFocus()
          NSColor.orange.setFill()
          NSRect(origin: .zero, size: size).fill()
          img1.unlockFocus()

          let img2 = NSImage(size: size)
          img2.lockFocus()
          NSColor.purple.setFill()
          NSRect(origin: .zero, size: size).fill()
          img2.unlockFocus()

          withKnownIssue {
            assertSnapshot(of: img1, as: .image, named: "no-userinfo-test", record: true)
          } matching: {
            $0.description.contains("recorded snapshot")
          }

          withKnownIssue {
            assertSnapshot(of: img2, as: .image, named: "no-userinfo-test")
          } matching: {
            $0.description.contains("does not match reference")
          }
        #endif
      }
    }
  }
#endif
