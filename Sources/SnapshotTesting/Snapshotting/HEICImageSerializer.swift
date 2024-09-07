import Foundation
import ImageIO
import UniformTypeIdentifiers
import ImageSerializer

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
/// A struct that provides encoding and decoding functionality for HEIC images.
///
/// `HEICCoder` supports encoding images to HEIC format and decoding HEIC data back into images.
///
/// - Note: The HEIC format is only supported on iOS 14.0+ and macOS 10.15+.
struct HEICCoder {
  /// Encodes a `SnapImage` into HEIC format.
  ///
  /// This method converts a `SnapImage` to `Data` using the HEIC format.
  ///
  /// - Parameter image: The image to be encoded. This can be a `UIImage` on iOS or an `NSImage` on macOS.
  ///
  /// - Returns: The encoded image data in HEIC format, or `nil` if encoding fails.
  ///
  /// - Note: The encoding quality is set to 0.8 (lossy compression). On macOS, the image is created using `CGImageDestinationCreateWithData`.
  static func encodeImage(_ image: SnapImage) -> Data? {
#if !os(macOS)
    guard let cgImage = image.cgImage else { return nil }
#else
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
#endif
    
    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(data, UTType.heic.identifier as CFString, 1, nil) else { return nil }
    CGImageDestinationAddImage(destination, cgImage, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { return nil }
    return data as Data
  }
  
  /// Decodes HEIC image data into a `SnapImage`.
  ///
  /// This method converts HEIC image data back into a `SnapImage`.
  ///
  /// - Parameter data: The HEIC data to be decoded.
  ///
  /// - Returns: The decoded image as `SnapImage`, or `nil` if decoding fails.
  ///
  /// - Note: On iOS, this returns a `UIImage`, while on macOS, it returns an `NSImage`.
  static func decodeImage(_ data: Data) -> SnapImage? {
#if !os(macOS)
    return UIImage(data: data)
#else
    return NSImage(data: data)
#endif
  }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension ImageSerializer {
  /// A static property that provides an `ImageSerializer` configured for HEIC format.
  ///
  /// This property creates an `ImageSerializer` instance that uses `HEICCoder` to handle encoding and decoding of HEIC images.
  ///
  /// - Returns: An `ImageSerializer` instance configured for HEIC format.
  ///
  /// - Note: This property is available only on iOS 14.0 and later.
  package static var heic: ImageSerializer {
    ImageSerializer(
      encodeImage: HEICCoder.encodeImage,
      decodeImage: HEICCoder.decodeImage
    )
  }
}
