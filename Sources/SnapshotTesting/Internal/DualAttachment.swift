import Foundation
import XCTest

#if canImport(Testing)
  import Testing
#endif

/// A wrapper that holds both XCTAttachment and the raw data for Swift Testing.
/// This dual approach ensures compatibility with both XCTest and Swift Testing.
internal struct DualAttachment {
  let xctAttachment: XCTAttachment
  let data: Data
  let uniformTypeIdentifier: String?
  let name: String?

  init(
    data: Data,
    uniformTypeIdentifier: String? = nil,
    name: String? = nil
  ) {
    self.data = data
    self.uniformTypeIdentifier = uniformTypeIdentifier
    self.name = name

    // Create XCTAttachment
    if let uniformTypeIdentifier = uniformTypeIdentifier {
      let attachment = XCTAttachment(
        uniformTypeIdentifier: uniformTypeIdentifier,
        name: name ?? "attachment",
        payload: data,
        userInfo: nil
      )
      attachment.name = name
      self.xctAttachment = attachment
    } else {
      let attachment = XCTAttachment(data: data)
      attachment.name = name
      self.xctAttachment = attachment
    }
  }

  #if os(iOS) || os(tvOS)
    init(image: UIImage, name: String? = nil) {
      var imageData: Data?

      // Try PNG first
      imageData = image.pngData()

      // If image is too large (>10MB), try JPEG compression
      if let data = imageData, data.count > 10_485_760 {
        #if DEBUG
        print("[SnapshotTesting] Large image (\(data.count) bytes) detected, compressing with JPEG")
        #endif
        if let jpegData = image.jpegData(compressionQuality: 0.8) {
          imageData = jpegData
        }
      }

      // Handle potential conversion failure
      if imageData == nil {
        #if DEBUG
        assertionFailure("[SnapshotTesting] Failed to convert UIImage to data for attachment '\(name ?? "unnamed")'")
        #endif
        imageData = Data()  // Fallback to empty data
      }

      let finalData = imageData!
      self.data = finalData
      self.uniformTypeIdentifier = "public.png"
      self.name = name

      // Warn if attachment is extremely large
      #if DEBUG
      if finalData.count > 50_000_000 {  // 50MB
        print("[SnapshotTesting] Warning: Attachment '\(name ?? "unnamed")' is very large (\(finalData.count / 1_000_000)MB)")
      }
      #endif

      // Create XCTAttachment from image directly for better compatibility
      self.xctAttachment = XCTAttachment(image: image)
      self.xctAttachment.name = name
    }
  #elseif os(macOS)
    init(image: NSImage, name: String? = nil) {
      var imageData: Data?

      // Convert NSImage to Data
      if let tiffData = image.tiffRepresentation,
        let bitmapImage = NSBitmapImageRep(data: tiffData)
      {
        imageData = bitmapImage.representation(using: .png, properties: [:])

        // If image is too large (>10MB), try JPEG compression
        if let data = imageData, data.count > 10_485_760 {
          #if DEBUG
          print("[SnapshotTesting] Large image (\(data.count) bytes) detected, compressing with JPEG")
          #endif
          if let jpegData = bitmapImage.representation(
            using: .jpeg, properties: [.compressionFactor: 0.8])
          {
            imageData = jpegData
          }
        }
      }

      // Handle potential conversion failure
      if imageData == nil {
        #if DEBUG
        assertionFailure("[SnapshotTesting] Failed to convert NSImage to data for attachment '\(name ?? "unnamed")'")
        #endif
        imageData = Data()  // Fallback to empty data
      }

      let finalData = imageData!
      self.data = finalData
      self.uniformTypeIdentifier = "public.png"
      self.name = name

      // Warn if attachment is extremely large
      #if DEBUG
      if finalData.count > 50_000_000 {  // 50MB
        print("[SnapshotTesting] Warning: Attachment '\(name ?? "unnamed")' is very large (\(finalData.count / 1_000_000)MB)")
      }
      #endif

      // Create XCTAttachment from image directly for better compatibility
      self.xctAttachment = XCTAttachment(image: image)
      self.xctAttachment.name = name
    }
  #endif

  /// Record this attachment in the current test context.
  /// This method handles both XCTest and Swift Testing contexts.
  func record(
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    #if canImport(Testing)
      #if compiler(>=6.2)
        // Check if we're in a Swift Testing context
        guard Test.current != nil else {
          #if DEBUG
          // This is expected when running under XCTest, so we don't need to warn
          // Only log if explicitly trying to use Swift Testing features
          if ProcessInfo.processInfo.environment["SWIFT_TESTING_ENABLED"] == "1" {
            print("[SnapshotTesting] Warning: Test.current is nil, unable to record Swift Testing attachment")
          }
          #endif
          return
        }

        // Check attachment size before recording
        #if DEBUG
        if data.count > 100_000_000 {  // 100MB hard limit in debug
          assertionFailure("[SnapshotTesting] Attachment '\(name ?? "unnamed")' exceeds 100MB limit (\(data.count / 1_000_000)MB)")
          return
        }
        #endif

        // Use Swift Testing's Attachment API
        Attachment.record(
          data,
          named: name,
          sourceLocation: SourceLocation(
            fileID: fileID.description,
            filePath: filePath.description,
            line: Int(line),
            column: Int(column)
          )
        )
      #endif
    #endif
  }
}

// Helper to convert arrays
extension Array where Element == XCTAttachment {
  func toDualAttachments() -> [DualAttachment] {
    // We can't extract data from existing XCTAttachments,
    // so this is mainly for migration purposes
    return []
  }
}

extension Array where Element == DualAttachment {
  func toXCTAttachments() -> [XCTAttachment] {
    return self.map { $0.xctAttachment }
  }
}
