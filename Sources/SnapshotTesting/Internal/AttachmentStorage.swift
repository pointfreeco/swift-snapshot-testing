import Foundation
import XCTest

/// Thread-safe storage for DualAttachments during test execution
internal final class AttachmentStorage: @unchecked Sendable {
  private static var storage: [String: [DualAttachment]] = [:]
  private static let lock = NSLock()

  /// Store DualAttachments for a given XCTAttachment array
  static func store(_ dualAttachments: [DualAttachment], for xctAttachments: [XCTAttachment]) {
    guard !dualAttachments.isEmpty, !xctAttachments.isEmpty else { return }

    lock.lock()
    defer { lock.unlock() }

    let key = generateKey(for: xctAttachments)
    storage[key] = dualAttachments
  }

  /// Retrieve DualAttachments for a given XCTAttachment array
  static func retrieve(for xctAttachments: [XCTAttachment]) -> [DualAttachment]? {
    guard !xctAttachments.isEmpty else { return nil }

    lock.lock()
    defer { lock.unlock() }

    let key = generateKey(for: xctAttachments)
    return storage[key]
  }

  /// Clear stored attachments (call after recording)
  static func clear(for xctAttachments: [XCTAttachment]) {
    guard !xctAttachments.isEmpty else { return }

    lock.lock()
    defer { lock.unlock() }

    let key = generateKey(for: xctAttachments)
    storage.removeValue(forKey: key)
  }

  private static func generateKey(for xctAttachments: [XCTAttachment]) -> String {
    // Create stable key from object identifier and count
    let primaryID = ObjectIdentifier(xctAttachments[0])
    let count = xctAttachments.count
    return "\(primaryID)-\(count)"
  }
}
