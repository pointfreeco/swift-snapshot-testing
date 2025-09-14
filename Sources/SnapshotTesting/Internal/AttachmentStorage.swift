import Foundation

#if !os(Linux) && !os(Android) && !os(Windows) && canImport(XCTest)
  import XCTest

  /// Thread-safe storage for DualAttachments during test execution
  internal final class AttachmentStorage: @unchecked Sendable {
    private static var storage: [UUID: DualAttachment] = [:]
    private static let lock = NSLock()
    private static let storageKeyPrefix = "st-attachment-"

    /// Store DualAttachments and embed their UUIDs in XCTAttachment names
    static func store(_ dualAttachments: [DualAttachment], for xctAttachments: [XCTAttachment]) {
      guard !dualAttachments.isEmpty,
            dualAttachments.count == xctAttachments.count else { return }

      lock.lock()
      defer { lock.unlock() }

      // Store each DualAttachment by its UUID and embed the UUID in the XCTAttachment name
      for (dual, xct) in zip(dualAttachments, xctAttachments) {
        storage[dual.id] = dual

        // Embed the UUID in the XCTAttachment name for later retrieval
        let existingName = xct.name ?? ""
        xct.name = "\(storageKeyPrefix)\(dual.id.uuidString)|\(existingName)"
      }
    }

    /// Retrieve DualAttachments for a given XCTAttachment array
    static func retrieve(for xctAttachments: [XCTAttachment]) -> [DualAttachment]? {
      guard !xctAttachments.isEmpty else { return nil }

      lock.lock()
      defer { lock.unlock() }

      var dualAttachments: [DualAttachment] = []

      for xct in xctAttachments {
        guard let name = xct.name,
              let uuid = extractUUID(from: name),
              let dual = storage[uuid] else { continue }

        dualAttachments.append(dual)
      }

      return dualAttachments.isEmpty ? nil : dualAttachments
    }

    /// Clear stored attachments (call after recording)
    static func clear(for xctAttachments: [XCTAttachment]) {
      guard !xctAttachments.isEmpty else { return }

      lock.lock()
      defer { lock.unlock() }

      for xct in xctAttachments {
        guard let name = xct.name,
              let uuid = extractUUID(from: name) else { continue }

        storage.removeValue(forKey: uuid)

        // Restore original name by removing UUID prefix
        if let pipeIndex = name.firstIndex(of: "|") {
          let originalName = String(name[name.index(after: pipeIndex)...])
          xct.name = originalName.isEmpty ? nil : originalName
        }
      }
    }

    /// Extract UUID from attachment name
    private static func extractUUID(from name: String) -> UUID? {
      guard name.hasPrefix(storageKeyPrefix) else { return nil }

      let withoutPrefix = String(name.dropFirst(storageKeyPrefix.count))
      guard let pipeIndex = withoutPrefix.firstIndex(of: "|") else { return nil }

      let uuidString = String(withoutPrefix[..<pipeIndex])
      return UUID(uuidString: uuidString)
    }
  }
#endif
