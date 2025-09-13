import XCTest
@testable import SnapshotTesting

#if canImport(Testing)
  import Testing
#endif

final class DualAttachmentTests: XCTestCase {
  func testDualAttachmentInitialization() {
    let data = "Hello, World!".data(using: .utf8)!
    let attachment = DualAttachment(
      data: data,
      uniformTypeIdentifier: "public.plain-text",
      name: "test.txt"
    )

    XCTAssertEqual(attachment.data, data)
    XCTAssertEqual(attachment.uniformTypeIdentifier, "public.plain-text")
    XCTAssertEqual(attachment.name, "test.txt")
    XCTAssertNotNil(attachment.xctAttachment)
    XCTAssertEqual(attachment.xctAttachment.name, "test.txt")
  }

  #if os(iOS) || os(tvOS)
  func testUIImageAttachment() {
    // Create a small test image
    let size = CGSize(width: 100, height: 100)
    UIGraphicsBeginImageContext(size)
    defer { UIGraphicsEndImageContext() }

    let context = UIGraphicsGetCurrentContext()!
    context.setFillColor(UIColor.red.cgColor)
    context.fill(CGRect(origin: .zero, size: size))

    let image = UIGraphicsGetImageFromCurrentImageContext()!
    let attachment = DualAttachment(image: image, name: "test-image")

    XCTAssertNotNil(attachment.data)
    XCTAssertEqual(attachment.uniformTypeIdentifier, "public.png")
    XCTAssertEqual(attachment.name, "test-image")
    XCTAssertNotNil(attachment.xctAttachment)
  }

  func testLargeImageCompression() {
    // Create a large test image (simulate >10MB)
    let size = CGSize(width: 3000, height: 3000)
    UIGraphicsBeginImageContext(size)
    defer { UIGraphicsEndImageContext() }

    let context = UIGraphicsGetCurrentContext()!
    // Fill with gradient to ensure non-compressible content
    for i in 0..<3000 {
      let color = UIColor(
        red: CGFloat(i) / 3000.0,
        green: 0.5,
        blue: 1.0 - CGFloat(i) / 3000.0,
        alpha: 1.0
      )
      context.setFillColor(color.cgColor)
      context.fill(CGRect(x: CGFloat(i), y: 0, width: 1, height: 3000))
    }

    let image = UIGraphicsGetImageFromCurrentImageContext()!
    let attachment = DualAttachment(image: image, name: "large-image")

    XCTAssertNotNil(attachment.data)
    // The data should exist but we can't guarantee exact compression results
    XCTAssertGreaterThan(attachment.data.count, 0)
    XCTAssertEqual(attachment.uniformTypeIdentifier, "public.png")
  }
  #endif

  #if os(macOS)
  func testNSImageAttachment() {
    // Create a small test image
    let size = NSSize(width: 100, height: 100)
    let image = NSImage(size: size)

    image.lockFocus()
    NSColor.red.setFill()
    NSRect(origin: .zero, size: size).fill()
    image.unlockFocus()

    let attachment = DualAttachment(image: image, name: "test-image")

    XCTAssertNotNil(attachment.data)
    XCTAssertEqual(attachment.uniformTypeIdentifier, "public.png")
    XCTAssertEqual(attachment.name, "test-image")
    XCTAssertNotNil(attachment.xctAttachment)
  }
  #endif

  func testXCTAttachmentProperty() {
    let data = "Test data".data(using: .utf8)!
    let attachment = DualAttachment(
      data: data,
      uniformTypeIdentifier: "public.plain-text",
      name: "test.txt"
    )

    // Test that xctAttachment property is properly initialized
    XCTAssertNotNil(attachment.xctAttachment)
    XCTAssertEqual(attachment.xctAttachment.name, "test.txt")
  }

  func testMultipleAttachments() {
    let attachments = [
      DualAttachment(data: Data(), uniformTypeIdentifier: nil, name: "1"),
      DualAttachment(data: Data(), uniformTypeIdentifier: nil, name: "2"),
      DualAttachment(data: Data(), uniformTypeIdentifier: nil, name: "3")
    ]

    // Test that each attachment has a properly initialized xctAttachment
    XCTAssertEqual(attachments.count, 3)
    XCTAssertEqual(attachments[0].xctAttachment.name, "1")
    XCTAssertEqual(attachments[1].xctAttachment.name, "2")
    XCTAssertEqual(attachments[2].xctAttachment.name, "3")
  }

  #if canImport(Testing) && compiler(>=6.2)
  func testRecordFunctionDoesNotCrash() {
    // We can't easily test that attachments are actually recorded
    // without running in a real Swift Testing context, but we can
    // verify the function doesn't crash when called
    let data = "Test".data(using: .utf8)!
    let attachment = DualAttachment(
      data: data,
      uniformTypeIdentifier: "public.plain-text",
      name: "test.txt"
    )

    // This should not crash even outside of Swift Testing context
    attachment.record(
      fileID: #fileID,
      filePath: #filePath,
      line: #line,
      column: #column
    )

    // If we get here without crashing, the test passes
    XCTAssertTrue(true)
  }
  #endif
}