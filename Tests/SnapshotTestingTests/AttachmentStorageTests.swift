import XCTest
@testable import SnapshotTesting

final class AttachmentStorageTests: XCTestCase {
  func testStoreAndRetrieve() {
    let dualAttachments = [
      DualAttachment(data: Data(), uniformTypeIdentifier: nil, name: "test1"),
      DualAttachment(data: Data(), uniformTypeIdentifier: nil, name: "test2")
    ]

    let xctAttachments = dualAttachments.map { $0.xctAttachment }

    // Store attachments
    AttachmentStorage.store(dualAttachments, for: xctAttachments)

    // Retrieve attachments
    let retrieved = AttachmentStorage.retrieve(for: xctAttachments)
    XCTAssertNotNil(retrieved)
    XCTAssertEqual(retrieved?.count, 2)
    XCTAssertEqual(retrieved?[0].name, "test1")
    XCTAssertEqual(retrieved?[1].name, "test2")

    // Clear attachments
    AttachmentStorage.clear(for: xctAttachments)

    // Verify cleared
    let afterClear = AttachmentStorage.retrieve(for: xctAttachments)
    XCTAssertNil(afterClear)
  }

  func testEmptyArrayHandling() {
    let emptyDual: [DualAttachment] = []
    let emptyXCT: [XCTAttachment] = []

    // Should handle empty arrays gracefully
    AttachmentStorage.store(emptyDual, for: emptyXCT)
    let retrieved = AttachmentStorage.retrieve(for: emptyXCT)
    XCTAssertNil(retrieved)

    // Clear should also handle empty arrays
    AttachmentStorage.clear(for: emptyXCT)
  }

  func testThreadSafety() {
    let expectation = XCTestExpectation(description: "Thread safety test")
    expectation.expectedFulfillmentCount = 100

    let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
    let group = DispatchGroup()

    // Create multiple attachments
    var allAttachments: [(dual: [DualAttachment], xct: [XCTAttachment])] = []
    for i in 0..<100 {
      let dual = [DualAttachment(
        data: "\(i)".data(using: .utf8)!,
        uniformTypeIdentifier: nil,
        name: "attachment-\(i)"
      )]
      let xct = dual.map { $0.xctAttachment }
      allAttachments.append((dual: dual, xct: xct))
    }

    // Concurrent reads and writes
    for (index, attachments) in allAttachments.enumerated() {
      group.enter()
      queue.async {
        // Store
        AttachmentStorage.store(attachments.dual, for: attachments.xct)

        // Retrieve
        let retrieved = AttachmentStorage.retrieve(for: attachments.xct)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.first?.name, "attachment-\(index)")

        // Clear
        if index % 2 == 0 {
          AttachmentStorage.clear(for: attachments.xct)
        }

        expectation.fulfill()
        group.leave()
      }
    }

    wait(for: [expectation], timeout: 10.0)
  }

  func testMultipleStorageKeys() {
    // Test that different XCTAttachment arrays get different storage
    let dual1 = [DualAttachment(data: Data(), uniformTypeIdentifier: nil, name: "set1")]
    let xct1 = dual1.map { $0.xctAttachment }

    let dual2 = [DualAttachment(data: Data(), uniformTypeIdentifier: nil, name: "set2")]
    let xct2 = dual2.map { $0.xctAttachment }

    AttachmentStorage.store(dual1, for: xct1)
    AttachmentStorage.store(dual2, for: xct2)

    let retrieved1 = AttachmentStorage.retrieve(for: xct1)
    let retrieved2 = AttachmentStorage.retrieve(for: xct2)

    XCTAssertEqual(retrieved1?.first?.name, "set1")
    XCTAssertEqual(retrieved2?.first?.name, "set2")

    // Clear one shouldn't affect the other
    AttachmentStorage.clear(for: xct1)
    XCTAssertNil(AttachmentStorage.retrieve(for: xct1))
    XCTAssertNotNil(AttachmentStorage.retrieve(for: xct2))
  }

  func testOverwriteExisting() {
    let xctAttachments = [XCTAttachment(data: Data())]

    let dual1 = [DualAttachment(data: Data(), uniformTypeIdentifier: nil, name: "first")]
    AttachmentStorage.store(dual1, for: xctAttachments)

    let dual2 = [DualAttachment(data: Data(), uniformTypeIdentifier: nil, name: "second")]
    AttachmentStorage.store(dual2, for: xctAttachments)

    // Should have overwritten the first storage
    let retrieved = AttachmentStorage.retrieve(for: xctAttachments)
    XCTAssertEqual(retrieved?.first?.name, "second")
  }
}