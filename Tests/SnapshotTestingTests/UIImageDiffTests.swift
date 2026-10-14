#if os(iOS) || os(tvOS)
  import UIKit
  import XCTest

  @testable import SnapshotTesting

  final class UIImageDiffTests: XCTestCase {
    private struct Pixel: Equatable {
      let x: Int
      let y: Int
    }

    private let width = 32
    private let height = 32
    private let changedPixel = Pixel(x: 11, y: 5)

    func testDifferenceHighlightsChangedPixelWhenReferenceIsGrayscale() throws {
      // A fully achromatic reference round-trips through PNG as 8-bit grayscale (1 byte per pixel).
      let reference = try image(
        colorSpace: CGColorSpaceCreateDeviceGray(),
        bitsPerComponent: 8,
        bitmapInfo: CGImageAlphaInfo.none.rawValue,
        lit: changedPixel
      )
      let snapshot = try rgbaImage(lit: nil)

      XCTAssertEqual(try changedPixels(reference, snapshot), [changedPixel])
    }

    func testDifferenceHighlightsChangedPixelWhenReferenceIs16BitRGBA() throws {
      // 16-bit RGBA references (e.g. Display P3 renders) are 8 bytes per pixel.
      let reference = try image(
        colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitsPerComponent: 16,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
          | CGBitmapInfo.byteOrder16Little.rawValue,
        lit: changedPixel
      )
      let snapshot = try rgbaImage(lit: nil)

      XCTAssertEqual(try changedPixels(reference, snapshot), [changedPixel])
    }

    func testDifferenceHighlightsChangedPixelWhenBothImagesAreRGBA() throws {
      let reference = try rgbaImage(lit: changedPixel)
      let snapshot = try rgbaImage(lit: nil)

      XCTAssertEqual(try changedPixels(reference, snapshot), [changedPixel])
    }

    // MARK: - Helpers

    private func rgbaImage(lit pixel: Pixel?) throws -> UIImage {
      try image(
        colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitsPerComponent: 8,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue,
        lit: pixel
      )
    }

    /// An opaque black image, optionally with a single white pixel.
    private func image(
      colorSpace: CGColorSpace,
      bitsPerComponent: Int,
      bitmapInfo: UInt32,
      lit pixel: Pixel?
    ) throws -> UIImage {
      let context = try XCTUnwrap(
        CGContext(
          data: nil,
          width: width,
          height: height,
          bitsPerComponent: bitsPerComponent,
          bytesPerRow: 0,
          space: colorSpace,
          bitmapInfo: bitmapInfo
        )
      )
      context.setFillColor(CGColor(gray: 0, alpha: 1))
      context.fill(CGRect(x: 0, y: 0, width: width, height: height))
      if let pixel {
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        // Core Graphics' origin is bottom-left; `Pixel` is top-left like the bitmap rows.
        context.fill(CGRect(x: pixel.x, y: height - 1 - pixel.y, width: 1, height: 1))
      }
      return UIImage(cgImage: try XCTUnwrap(context.makeImage()), scale: 1, orientation: .up)
    }

    /// Runs the `.image` diffing strategy and returns the pixels lit in its `difference.png`.
    private func changedPixels(_ reference: UIImage, _ snapshot: UIImage) throws -> [Pixel] {
      let (_, attachments) = try XCTUnwrap(Diffing<UIImage>.image.diffV2(reference, snapshot))
      let differenceData = try XCTUnwrap(
        attachments.lazy.compactMap { attachment -> Data? in
          guard case .data(let data, let name) = attachment, name == "difference.png" else {
            return nil
          }
          return data
        }.first
      )
      let difference = try XCTUnwrap(UIImage(data: differenceData)?.cgImage)
      XCTAssertEqual(difference.width, width)
      XCTAssertEqual(difference.height, height)

      var bytes = [UInt8](repeating: 0, count: width * height)
      let context = try XCTUnwrap(
        CGContext(
          data: &bytes,
          width: width,
          height: height,
          bitsPerComponent: 8,
          bytesPerRow: width,
          space: CGColorSpaceCreateDeviceGray(),
          bitmapInfo: CGImageAlphaInfo.none.rawValue
        )
      )
      context.draw(difference, in: CGRect(x: 0, y: 0, width: width, height: height))
      return bytes.indices
        .filter { bytes[$0] != 0 }
        .map { Pixel(x: $0 % width, y: $0 / width) }
    }
  }
#endif
