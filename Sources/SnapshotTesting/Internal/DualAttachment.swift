import Foundation

#if !os(Linux) && !os(Android) && !os(Windows) && canImport(XCTest)
  import XCTest

  /// A wrapper that holds both XCTAttachment and the raw data for Swift Testing
  internal struct DualAttachment {
  let id: UUID
  let xctAttachment: XCTAttachment
  let data: Data
  let uniformTypeIdentifier: String?
  let name: String?

  init(
    data: Data,
    uniformTypeIdentifier: String? = nil,
    name: String? = nil
  ) {
    self.id = UUID()
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
      // Always use PNG for stable, deterministic diffs
      let imageData = image.pngData() ?? Data()

      self.id = UUID()
      self.data = imageData
      self.uniformTypeIdentifier = "public.png"
      self.name = name

      // Create XCTAttachment from image directly for better compatibility
      self.xctAttachment = XCTAttachment(image: image)
      self.xctAttachment.name = name
    }
  #elseif os(macOS)
    init(image: NSImage, name: String? = nil) {
      // Always use PNG for stable, deterministic diffs
      var imageData = Data()

      // Convert NSImage to PNG Data
      if let tiffData = image.tiffRepresentation,
        let bitmapImage = NSBitmapImageRep(data: tiffData)
      {
        imageData = bitmapImage.representation(using: .png, properties: [:]) ?? Data()
      }

      self.id = UUID()
      self.data = imageData
      self.uniformTypeIdentifier = "public.png"
      self.name = name

      // Create XCTAttachment from image directly for better compatibility
      self.xctAttachment = XCTAttachment(image: image)
      self.xctAttachment.name = name
    }
  #endif

  /// Record this attachment in the current test context
  func record(
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    STAttachments.record(
      data,
      named: name,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
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
#endif
