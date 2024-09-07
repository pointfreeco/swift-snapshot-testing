import Foundation
import webp
import ImageSerializer

extension ImageSerializer {
  /// A static property that provides an `ImageSerializer` for the WebP format.
  ///
  /// This property uses the `WebPEncoder` and `WebPDecoder` to encode and decode images in the WebP format.
  ///
  /// - Returns: An `ImageSerializer` instance configured for encoding and decoding WebP images.
  ///
  /// - Encoding:
  ///   - The `encodeImage` closure uses `WebPEncoder.encode(_:config:)` to convert a `SnapImage` into `Data` with the specified encoding configuration.
  ///   - The configuration used is `.preset(.picture, quality: 80)`, which applies a preset for general picture quality.
  /// - Decoding:
  ///   - The `decodeImage` closure uses `WebPDecoder.decode(toImage:options:)` to convert `Data` back into a `SnapImage` with specified decoding options.
  ///
  /// - Note: The encoding and decoding operations are performed using the `webp` library, which supports the WebP format.
  package static var webp: Self {
    return ImageSerializer { image in
      try? WebPEncoder().encode(image, config: .preset(.picture, quality: 80))
    } decodeImage: { data in
      try? WebPDecoder().decode(toImage: data, options: WebpDecoderOptions())
    }
  }
}
