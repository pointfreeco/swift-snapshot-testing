import Foundation
import XCTest

/// Thread-safe storage for DualAttachments during test execution
/// This class provides temporary storage for attachments during test execution,
/// ensuring they can be retrieved when needed for Swift Testing's attachment API.
internal final class AttachmentStorage: @unchecked Sendable {
  private static var storage: [String: [DualAttachment]] = [:]
  private static let lock = NSLock()

  #if DEBUG
  /// Track active storage keys for leak detection
  private static var activeKeys: Set<String> = []
  #endif

  /// Store DualAttachments for a given XCTAttachment array
  /// - Parameters:
  ///   - dualAttachments: The DualAttachment instances to store
  ///   - xctAttachments: The corresponding XCTAttachment instances used to generate a storage key
  static func store(_ dualAttachments: [DualAttachment], for xctAttachments: [XCTAttachment]) {
    guard !dualAttachments.isEmpty, !xctAttachments.isEmpty else { return }

    lock.lock()
    defer { lock.unlock() }

    // Create a stable key using combination of object identifiers
    // This prevents issues if the array is modified after storage
    let key = generateKey(for: xctAttachments)
    storage[key] = dualAttachments

    #if DEBUG
    activeKeys.insert(key)
    if storage.count > 100 {
      assertionFailure("AttachmentStorage has \(storage.count) entries - possible memory leak")
    }
    #endif
  }

  /// Retrieve DualAttachments for a given XCTAttachment array
  /// - Parameter xctAttachments: The XCTAttachment instances used to look up stored DualAttachments
  /// - Returns: The stored DualAttachments if found, nil otherwise
  static func retrieve(for xctAttachments: [XCTAttachment]) -> [DualAttachment]? {
    guard !xctAttachments.isEmpty else { return nil }

    lock.lock()
    defer { lock.unlock() }

    let key = generateKey(for: xctAttachments)
    return storage[key]
  }

  /// Clear stored attachments (call after recording)
  /// - Parameter xctAttachments: The XCTAttachment instances whose DualAttachments should be cleared
  static func clear(for xctAttachments: [XCTAttachment]) {
    guard !xctAttachments.isEmpty else { return }

    lock.lock()
    defer { lock.unlock() }

    let key = generateKey(for: xctAttachments)
    storage.removeValue(forKey: key)

    #if DEBUG
    activeKeys.remove(key)
    #endif
  }

  /// Generate a stable key for the given attachments
  /// Uses a combination of object identifiers to create a unique key
  private static func generateKey(for xctAttachments: [XCTAttachment]) -> String {
    // Create key from first attachment's identifier and count for stability
    let primaryID = ObjectIdentifier(xctAttachments[0])
    let count = xctAttachments.count
    return "\(primaryID)-\(count)"
  }

  #if DEBUG
  /// Verify all attachments have been properly cleaned up
  /// Call this in test tearDown to detect memory leaks
  static func verifyCleanup() {
    lock.lock()
    defer { lock.unlock() }

    if !activeKeys.isEmpty {
      assertionFailure("AttachmentStorage has \(activeKeys.count) uncleaned entries: \(activeKeys)")
    }
  }

  /// Get current storage count for debugging
  static var debugStorageCount: Int {
    lock.lock()
    defer { lock.unlock() }
    return storage.count
  }
  #endif
}
