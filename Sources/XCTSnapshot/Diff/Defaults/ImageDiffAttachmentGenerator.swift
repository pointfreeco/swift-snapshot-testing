#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(macOS)
@preconcurrency import AppKit
#endif
@preconcurrency import XCTest

/// Generates messages and visual attachments highlighting differences between images in snapshot tests.
///
/// `ImageDiffAttachmentGenerator` compares two `ImageBytes` instances (serialized images)
/// and returns a textual description of differences along with visual attachments (e.g., images highlighting discrepancies).
/// Used to facilitate visual change detection in UI tests.
public struct ImageDiffAttachmentGenerator: DiffAttachmentGenerator {

  private let precision: Float
  private let perceptualPrecision: Float

  /// Initializes the generator with precision and scaling parameters.
  ///
  /// - Parameter precision: Allowed pixel difference threshold (e.g., `1.0` for identical pixels).
  /// - Parameter perceptualPrecision: Color difference threshold for perceptual comparison (useful for less strict comparisons).
  /// - Parameter scale: Scaling factor applied during image comparison (e.g., `2.0` for high-resolution images).
  public init(
    precision: Float,
    perceptualPrecision: Float
  ) {
    self.precision = precision
    self.perceptualPrecision = perceptualPrecision
  }

  /// Compares two images and generates a descriptive message or visual attachments highlighting differences.
  ///
  /// - Parameter reference: Reference image (original snapshot).
  /// - Parameter diffable: Image to compare (new snapshot version).
  /// - Returns: `DiffAttachment` containing a descriptive message and visual attachments if significant differences exist.
  public func callAsFunction(
    from reference: ImageBytes,
    with diffable: ImageBytes
  ) -> DiffAttachment? {
    performOnMainThread {
      guard let message = reference.rawValue.compare(
        diffable.rawValue,
        precision: precision,
        perceptualPrecision: perceptualPrecision
      ) else { return nil }
      
      let difference = reference.rawValue.substract(diffable.rawValue)
      let oldAttachment = XCTAttachment(unsafeImage: reference.rawValue)
      oldAttachment?.name = "reference"
      let isEmptyImage = diffable.rawValue.size == .zero
      let newAttachment = XCTAttachment(unsafeImage: isEmptyImage ? SDKImage.empty : diffable.rawValue)
      newAttachment?.name = "failure"
      let differenceAttachment = XCTAttachment(unsafeImage: difference)
      differenceAttachment?.name = "difference"
      
      return DiffAttachment(
        message: message,
        attachments: [oldAttachment, newAttachment, differenceAttachment].compactMap(\.self)
      )
    }
  }
}

extension XCTAttachment {

  fileprivate convenience init?(unsafeImage: SDKImage) {
    if unsafeImage.size == .zero {
      return nil
    }

    self.init(image: unsafeImage)
  }
}

extension XCTAttachment {

  struct Isolated: Sendable {
    let attachment: XCTAttachment
  }

  func isolated() -> Isolated {
    .init(attachment: self)
  }
}
