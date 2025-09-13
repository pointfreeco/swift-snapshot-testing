import Foundation
import XCTest

/// Thread-safe storage for DualAttachments during test execution
internal final class AttachmentStorage {
  private static let queue = DispatchQueue(label: "com.pointfree.SnapshotTesting.AttachmentStorage")
  private static var storage: [ObjectIdentifier: [DualAttachment]] = [:]

  /// Store DualAttachments for a given XCTAttachment array
  static func store(_ dualAttachments: [DualAttachment], for xctAttachments: [XCTAttachment]) {
    guard !dualAttachments.isEmpty, !xctAttachments.isEmpty else { return }

    queue.sync {
      // Store using the first XCTAttachment's identifier as key
      let key = ObjectIdentifier(xctAttachments[0])
      storage[key] = dualAttachments
    }
  }

  /// Retrieve DualAttachments for a given XCTAttachment array
  static func retrieve(for xctAttachments: [XCTAttachment]) -> [DualAttachment]? {
    guard !xctAttachments.isEmpty else { return nil }

    return queue.sync {
      let key = ObjectIdentifier(xctAttachments[0])
      return storage[key]
    }
  }

  /// Clear stored attachments (call after recording)
  static func clear(for xctAttachments: [XCTAttachment]) {
    guard !xctAttachments.isEmpty else { return }

    queue.sync {
      let key = ObjectIdentifier(xctAttachments[0])
      storage.removeValue(forKey: key)
    }
  }
}
