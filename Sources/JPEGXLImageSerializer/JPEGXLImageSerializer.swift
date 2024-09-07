import Foundation
import JxlCoder
import ImageSerializer

extension ImageSerializer {
  /// A static property that provides an `ImageSerializer` for the JPEG XL format.
  ///
  /// This property uses the `JXLCoder` to encode and decode images in the JPEG XL format.
  ///
  /// - Returns: An `ImageSerializer` instance configured for encoding and decoding JPEG XL images.
  ///
  /// - Encoding:
  ///   - The `encodeImage` closure uses `JXLCoder.encode(image:)` to convert a `SnapImage` into `Data`.
  /// - Decoding:
  ///   - The `decodeImage` closure uses `JXLCoder.decode(data:)` to convert `Data` back into a `SnapImage`.
  ///
  /// - Note: The encoding and decoding operations are performed using the `JXLCoder` library, which supports the JPEG XL format.
  package static var jxl: Self {
    return ImageSerializer { image in
      try? JXLCoder.encode(image: image)
    } decodeImage: { data in
      try? JXLCoder.decode(data: data)
    }
  }
}
