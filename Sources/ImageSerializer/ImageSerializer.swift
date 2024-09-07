import Foundation

#if !os(macOS)
import UIKit.UIImage
/// A type alias for `UIImage` on iOS and `NSImage` on macOS.
package typealias SnapImage = UIImage
#else
import AppKit.NSImage
/// A type alias for `UIImage` on iOS and `NSImage` on macOS.
package typealias SnapImage = NSImage
#endif

/// A structure responsible for encoding and decoding images.
///
/// The `ImageSerializer` structure provides two closures:
/// - `encodeImage`: Encodes a `SnapImage` into `Data`.
/// - `decodeImage`: Decodes `Data` back into a `SnapImage`.
///
/// These closures allow you to define custom image serialization logic for different image formats.
package struct ImageSerializer {
  /// A closure that encodes a `SnapImage` into `Data`.
  package var encodeImage: (_ image: SnapImage) -> Data?
  
  /// A closure that decodes `Data` into a `SnapImage`.
  package var decodeImage: (_ data: Data) -> SnapImage?
  
  /// Initializes an `ImageSerializer` with custom encoding and decoding logic.
  ///
  /// - Parameters:
  ///   - encodeImage: A closure that defines how to encode a `SnapImage` into `Data`.
  ///   - decodeImage: A closure that defines how to decode `Data` into a `SnapImage`.
  package init(encodeImage: @escaping (_: SnapImage) -> Data?, decodeImage: @escaping (_: Data) -> SnapImage?) {
    self.encodeImage = encodeImage
    self.decodeImage = decodeImage
  }
}

/// An enumeration of supported image formats.
///
/// `ImageFormat` defines the formats that can be used for image serialization:
/// - `.jxl`: JPEG XL format.
/// - `.png`: PNG format.
/// - `.heic`: HEIC format.
/// - `.webp`: WEBP format.
///
/// The `defaultValue` is set to `.png`.
public enum ImageFormat: String {
  case jxl
  case png
  case heic
  case webp

  /// The default image format, set to `.png`.
  public static var defaultValue = ImageFormat.png
}
