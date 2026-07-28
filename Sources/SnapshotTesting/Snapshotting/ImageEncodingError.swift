#if os(iOS) || os(tvOS) || os(macOS)
  import CoreGraphics
  import CoreImage
  import Foundation

  #if os(macOS)
    import AppKit
  #else
    import UIKit
  #endif

  /// A snapshot that couldn't be encoded as a PNG image, described so the cause can be fixed.
  struct ImageEncodingError: LocalizedError, Equatable {
    enum Reason: Equatable {
      /// The image has nothing to draw, which is what rendering a zero-size view produces.
      case noImageData(size: CGSize)
      /// The image is backed by a `CIImage` with an infinite extent, which can't be rendered.
      case infiniteCIImage
      /// A side is longer than ImageIO's PNG encoder allows.
      case tooLarge(width: Int, height: Int)
      /// ImageIO couldn't encode the image's bitmap.
      case encoderFailed(width: Int, height: Int)
    }

    /// ImageIO's PNG encoder rejects images with a longer side.
    static let maximumPixelsPerSide = 1_000_000

    let reason: Reason

    /// Classifies an image the encoder rejected from its pixel size and what backs it.
    init(pixelSize: CGSize, size: CGSize, ciImageExtent: CGRect?, hasImageData: Bool) {
      let width = Self.pixelCount(pixelSize.width)
      let height = Self.pixelCount(pixelSize.height)
      // Checked first: an infinite extent's clamped size would otherwise read as too large.
      if ciImageExtent?.isInfinite == true {
        reason = .infiniteCIImage
      } else if max(width, height) > Self.maximumPixelsPerSide {
        reason = .tooLarge(width: width, height: height)
      } else if !hasImageData || width == 0 || height == 0 {
        reason = .noImageData(size: size)
      } else {
        reason = .encoderFailed(width: width, height: height)
      }
    }

    init(reason: Reason) {
      self.reason = reason
    }

    // An infinite extent's size is a huge finite number, and sizes can be NaN, so the conversion
    // clamps rather than trapping.
    private static func pixelCount(_ length: CGFloat) -> Int {
      guard length.isFinite, length > 0 else { return 0 }
      // Rounded up, as renderers allocate whole pixels for a fractional size.
      return Int(min(length.rounded(.up), CGFloat(Int32.max)))
    }

    var errorDescription: String? {
      let cause: String
      switch reason {
      case .noImageData(let size) where size.width > 0 && size.height > 0:
        cause = "it is \(size) but has no image data to draw."
      case .noImageData(let size):
        cause = "its size is \(size). Give the view an explicit, non-zero size."
      case .infiniteCIImage:
        cause =
          "it is backed by a CIImage with an infinite extent, which can't be rendered. Crop the CIImage to a finite rect first, for example with cropped(to:)."
      case .tooLarge(let width, let height):
        cause =
          "it is \(width)×\(height) pixels, and ImageIO doesn't write PNG images with a side longer than \(Self.maximumPixelsPerSide) pixels. Snapshot a smaller size, or split the snapshot."
      case .encoderFailed(let width, let height):
        cause = "ImageIO failed to encode its \(width)×\(height) pixel bitmap."
      }
      return "The snapshot couldn't be encoded as a PNG image because \(cause)"
    }
  }

  #if os(macOS)
    extension ImageEncodingError {
      init(_ image: NSImage) {
        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        // Without a CGImage, which AppKit can't create for some oversized images, the largest
        // representation gives the pixel size.
        let largestRepresentation = image.representations.max {
          $0.pixelsWide * $0.pixelsHigh < $1.pixelsWide * $1.pixelsHigh
        }
        let pixelSize =
          cgImage.map { CGSize(width: $0.width, height: $0.height) }
          ?? largestRepresentation.map { CGSize(width: $0.pixelsWide, height: $0.pixelsHigh) }
          ?? image.size
        let ciImageExtent = image.representations.lazy
          .compactMap { ($0 as? NSCIImageRep)?.ciImage.extent }
          .first { $0.isInfinite }
        self.init(
          pixelSize: pixelSize, size: image.size,
          ciImageExtent: cgImage == nil ? ciImageExtent : nil, hasImageData: cgImage != nil)
      }
    }
  #else
    extension ImageEncodingError {
      init(_ image: UIImage) {
        // CIImage extents are in pixels; the size fallback is in points, so it's scaled.
        let pixelSize =
          image.cgImage.map { CGSize(width: $0.width, height: $0.height) }
          ?? image.ciImage?.extent.size
          ?? CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        self.init(
          pixelSize: pixelSize, size: image.size,
          ciImageExtent: image.cgImage == nil ? image.ciImage?.extent : nil,
          hasImageData: image.cgImage != nil || image.ciImage != nil)
      }
    }
  #endif
#endif
