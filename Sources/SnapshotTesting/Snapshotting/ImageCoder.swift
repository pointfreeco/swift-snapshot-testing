import Foundation
@_exported import ImageSerializer

#if canImport(JPEGXLImageSerializer)
import JPEGXLImageSerializer
#endif

/// Encodes an image into the specified format.
///
/// This function takes a `SnapImage` and encodes it into a `Data` representation using the specified `ImageFormat`.
///
/// - Parameters:
///   - image: The image to be encoded. This can be a `UIImage` on iOS or an `NSImage` on macOS.
///   - format: The format to encode the image into. Supported formats are `.png`, `.heic`, and `.jxl`.
///
/// - Returns: The encoded image as `Data`, or `nil` if encoding fails.
///
/// - Note:
///   - If the `.heic` format is selected and the platform does not support HEIC (iOS 14.0+), the image will be encoded as PNG.
///   - If the `.jxl` format is selected but `JPEGXLImageSerializer` is not available, the image will be encoded as PNG.
package func EncodeImage(image: SnapImage, _ format: ImageFormat) -> Data? {
  var serializer: ImageSerializer
  switch format {
#if canImport(JPEGXLImageSerializer)
    case .jxl: serializer = ImageSerializer.jxl
#else
    case .jxl: serializer = ImageSerializer.png
#endif
    case .png: serializer = ImageSerializer.png
    case .heic:
      if #available(iOS 14.0, *) {
        serializer = ImageSerializer.heic
      } else {
        serializer = ImageSerializer.png
      }
  }
  return serializer.encodeImage(image)
}

/// Decodes image data into a `SnapImage` of the specified format.
///
/// This function takes `Data` representing an encoded image and decodes it back into a `SnapImage`.
///
/// - Parameters:
///   - data: The data to be decoded into an image.
///   - format: The format of the image data. Supported formats are `.png`, `.heic`, and `.jxl`.
///
/// - Returns: The decoded `SnapImage`, or `nil` if decoding fails.
///
/// - Note:
///   - If the `.heic` format is selected and the platform does not support HEIC (iOS 14.0+), the image will be decoded as PNG.
///   - If the `.jxl` format is selected but `JPEGXLImageSerializer` is not available, the image will be decoded as PNG.
package func DecodeImage(data: Data, _ format: ImageFormat) -> SnapImage? {
  var serializer: ImageSerializer
  switch format {
#if canImport(JPEGXLImageSerializer)
    case .jxl: serializer = ImageSerializer.jxl
#else
    case .jxl: serializer = ImageSerializer.png
#endif
    case .png: serializer = ImageSerializer.png
    case .heic:
      if #available(iOS 14.0, *) {
        serializer = ImageSerializer.heic
      } else {
        serializer = ImageSerializer.png
      }
  }
  return serializer.decodeImage(data)
}
