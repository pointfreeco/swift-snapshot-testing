import XCTest
@testable import SnapshotTesting

final class AttachmentVerificationTests: XCTestCase {

  func testStringDiffCreatesOneAttachment() {
    // String diffs should only create 1 attachment (the diff patch) - keeping original behavior
    let diffing = Diffing<String>.lines

    let oldString = """
    Line 1
    Line 2
    Line 3
    """

    let newString = """
    Line 1
    Line 2 Modified
    Line 3
    Line 4 Added
    """

    // Perform the diff
    let result = diffing.diff(oldString, newString)

    // Verify we got a difference
    XCTAssertNotNil(result, "Should have found differences")

    // Verify we got exactly 1 attachment (just the patch file)
    let (_, attachments) = result!
    XCTAssertEqual(attachments.count, 1, "Should create 1 attachment for string diffs")

    // Verify the attachment contains the diff
    if let attachment = attachments.first {
      XCTAssertNotNil(attachment, "Should have an attachment")
      // Note: We can't easily verify the content since XCTAttachment doesn't expose its data
      // But we've verified it exists
    }
  }

  #if os(iOS) || os(tvOS)
  func testImageDiffCreatesThreeAttachments() {
    // Create two different images
    let size = CGSize(width: 10, height: 10)

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

    // Create image diffing
    let diffing = Diffing<UIImage>.image

    // Perform the diff
    let result = diffing.diff(redImage, blueImage)

    // Verify we got a difference
    XCTAssertNotNil(result, "Should have found differences between red and blue images")

    // Verify we got exactly 3 attachments
    let (_, attachments) = result!
    XCTAssertEqual(attachments.count, 3, "Should create 3 attachments for image diffs")

    // Verify attachment names
    let attachmentNames = attachments.compactMap { $0.name }
    XCTAssertTrue(attachmentNames.contains("reference"), "Should have reference attachment")
    XCTAssertTrue(attachmentNames.contains("failure"), "Should have failure attachment")
    XCTAssertTrue(attachmentNames.contains("difference"), "Should have difference attachment")

    // Verify DualAttachments were stored
    let dualAttachments = AttachmentStorage.retrieve(for: attachments)
    XCTAssertNotNil(dualAttachments, "DualAttachments should be stored")
    XCTAssertEqual(dualAttachments?.count, 3, "Should store 3 DualAttachments")

    // Verify all attachments have data
    if let dualAttachments = dualAttachments {
      for attachment in dualAttachments {
        XCTAssertGreaterThan(attachment.data.count, 0, "Attachment '\(attachment.name ?? "unnamed")' should have data")
        XCTAssertEqual(attachment.uniformTypeIdentifier, "public.png", "Image attachments should be PNG")
      }
    }

    // Clean up
    AttachmentStorage.clear(for: attachments)
  }
  #endif

  #if os(macOS)
  func testNSImageDiffCreatesThreeAttachments() {
    // Create two different images
    let size = NSSize(width: 10, height: 10)

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

    // Create image diffing
    let diffing = Diffing<NSImage>.image

    // Perform the diff
    let result = diffing.diff(redImage, blueImage)

    // Verify we got a difference
    XCTAssertNotNil(result, "Should have found differences between red and blue images")

    // Verify we got exactly 3 attachments
    let (_, attachments) = result!
    XCTAssertEqual(attachments.count, 3, "Should create 3 attachments for image diffs")

    // Verify attachment names
    let attachmentNames = attachments.compactMap { $0.name }
    XCTAssertTrue(attachmentNames.contains("reference"), "Should have reference attachment")
    XCTAssertTrue(attachmentNames.contains("failure"), "Should have failure attachment")
    XCTAssertTrue(attachmentNames.contains("difference"), "Should have difference attachment")

    // Verify DualAttachments were stored
    let dualAttachments = AttachmentStorage.retrieve(for: attachments)
    XCTAssertNotNil(dualAttachments, "DualAttachments should be stored")
    XCTAssertEqual(dualAttachments?.count, 3, "Should store 3 DualAttachments")

    // Verify all attachments have data
    if let dualAttachments = dualAttachments {
      for attachment in dualAttachments {
        XCTAssertGreaterThan(attachment.data.count, 0, "Attachment '\(attachment.name ?? "unnamed")' should have data")
        XCTAssertEqual(attachment.uniformTypeIdentifier, "public.png", "Image attachments should be PNG")
      }
    }

    // Clean up
    AttachmentStorage.clear(for: attachments)
  }
  #endif

  func testNoAttachmentsOnSuccess() {
    // When strings match, no attachments should be created
    let diffing = Diffing<String>.lines
    let sameString = "Same content"

    let result = diffing.diff(sameString, sameString)

    // Should return nil for matching content
    XCTAssertNil(result, "Should return nil when content matches")
  }

  func testAttachmentDataIntegrity() {
    // Test that attachment data is properly stored and retrieved
    let testData = "Test Data".data(using: .utf8)!
    let attachment = DualAttachment(
      data: testData,
      uniformTypeIdentifier: "public.plain-text",
      name: "test.txt"
    )

    // Verify data is stored correctly
    XCTAssertEqual(attachment.data, testData)

    // Verify XCTAttachment is created
    XCTAssertNotNil(attachment.xctAttachment)
    XCTAssertEqual(attachment.xctAttachment.name, "test.txt")

    // Store and retrieve
    let attachments = [attachment]
    let xctAttachments = attachments.map { $0.xctAttachment }

    AttachmentStorage.store(attachments, for: xctAttachments)
    let retrieved = AttachmentStorage.retrieve(for: xctAttachments)

    XCTAssertNotNil(retrieved)
    XCTAssertEqual(retrieved?.count, 1)
    XCTAssertEqual(retrieved?.first?.data, testData)

    // Clean up
    AttachmentStorage.clear(for: xctAttachments)
  }
}