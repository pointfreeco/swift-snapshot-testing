#if os(iOS) || os(tvOS) || os(macOS)
  import SnapshotTesting
  import XCTest

  #if os(macOS)
    import AppKit
  #else
    import UIKit
  #endif

  // Public API only, so this file also builds against upstream swift-snapshot-testing.
  final class ColorSpaceComparisonTests: XCTestCase {
    // Saturated, because grays encode identically in sRGB and Display P3. Exact 8-bit sRGB values,
    // so every layout below draws to the same 8-bit sRGB bytes.
    private let orange: [CGFloat] = [230 / 255, 102 / 255, 26 / 255]
    // Exact in every layout, so the changed pixel measures the same in every pair.
    private let black: [CGFloat] = [0, 0, 0]
    // One of the 16 × 16 pixels: 255 / 256.
    private let onePixelMismatch =
      "The percentage of pixels that match 0.99609375 is less than required 1.0"

    // [#1083](https://github.com/pointfreeco/swift-snapshot-testing/issues/1083), see also
    // [#1119](https://github.com/pointfreeco/swift-snapshot-testing/pull/1119): the same color in
    // Display P3 and sRGB failed every pixel.
    func testSameColorInDisplayP3AndSRGBMatchesPerceptually() throws {
      let diffing = imageDiffing(precision: 1, perceptualPrecision: 0.98)
      let displayP3 = try image(.displayP3, orange)
      let sRGB = try image(.sRGB, orange)
      XCTAssertNil(diffing.diffV2(displayP3, sRGB)?.0)
      XCTAssertNil(diffing.diffV2(sRGB, displayP3)?.0)

      // A changed pixel makes sure the perceptual comparison runs.
      for message in [
        diffing.diffV2(displayP3, try image(.sRGB, orange, changedPixel: black))?.0,
        diffing.diffV2(sRGB, try image(.displayP3, orange, changedPixel: black))?.0,
      ] {
        XCTAssertTrue(message?.hasPrefix(onePixelMismatch) == true, message ?? "nil")
      }
    }

    #if os(iOS) || os(tvOS)
      // [#1083](https://github.com/pointfreeco/swift-snapshot-testing/issues/1083): wide-gamut
      // simulators decode references as 16-bit Display P3 and capture half-float extended sRGB, and
      // a one-pixel change failed almost every pixel.
      func testOnePixelChangeAcrossColorSpacesReportsOnePixel() throws {
        let diffing = imageDiffing(precision: 1, perceptualPrecision: 0.999)
        let mixed = try XCTUnwrap(
          diffing.diffV2(
            try image(.displayP3SixteenBit, orange),
            try image(.extendedSRGBHalfFloat, orange, changedPixel: black)
          )?.0)
        // Both sides share a colorspace, so this is the expected one-pixel message.
        let sRGB = try XCTUnwrap(
          diffing.diffV2(try image(.sRGB, orange), try image(.sRGB, orange, changedPixel: black))?
            .0)
        XCTAssertEqual(mixed, sRGB)
        XCTAssertTrue(mixed.hasPrefix(onePixelMismatch), mixed)
      }

      // [#1083](https://github.com/pointfreeco/swift-snapshot-testing/issues/1083): rendering drift
      // between GPUs, one 8-bit step on every pixel.
      func testOneStepDriftAcrossColorSpacesIsWithinPerceptualPrecision() throws {
        let reference = try image(.displayP3SixteenBit, orange)
        let drifted = try image(.extendedSRGBHalfFloat, [orange[0], 103 / 255, orange[2]])
        XCTAssertNotNil(
          imageDiffing().diffV2(reference, drifted), "Reaches the perceptual comparison")
        XCTAssertNil(
          imageDiffing(precision: 1, perceptualPrecision: 0.98).diffV2(reference, drifted)?.0)
      }

      // [#1117](https://github.com/pointfreeco/swift-snapshot-testing/issues/1117): an alpha-less
      // 16-bit Display P3 reference, as PNG optimizers write it, against an extended sRGB snapshot.
      func testReferenceWithoutAlphaMatchesPerceptually() throws {
        let rgba = try cgImage(.displayP3SixteenBit, orange)
        // Opaque premultiplied components equal unpremultiplied ones, so the bytes are reused.
        let rgb = try XCTUnwrap(
          CGImage(
            width: rgba.width, height: rgba.height, bitsPerComponent: 16, bitsPerPixel: 64,
            bytesPerRow: rgba.bytesPerRow, space: XCTUnwrap(rgba.colorSpace),
            bitmapInfo: CGBitmapInfo(
              rawValue: CGImageAlphaInfo.noneSkipLast.rawValue
                | CGBitmapInfo.byteOrder16Little.rawValue),
            provider: XCTUnwrap(rgba.dataProvider), decode: nil, shouldInterpolate: false,
            intent: .defaultIntent))
        let png = try imageDiffing().toData(UIImage(cgImage: rgb))
        // Byte 25 is the PNG IHDR's color type; 2 is RGB.
        XCTAssertEqual(png[25], 2, "PNG IHDR color type RGB")
        let reference = try XCTUnwrap(UIImage(data: png, scale: 1))
        // Two 8-bit steps on one pixel: a real change, but within perceptualPrecision 0.98.
        let candidate = try image(
          .extendedSRGBHalfFloat, orange, changedPixel: [orange[0], 104 / 255, orange[2]])

        XCTAssertNotNil(
          imageDiffing().diffV2(reference, candidate), "Reaches the perceptual comparison")
        XCTAssertNil(
          imageDiffing(precision: 0.999, perceptualPrecision: 0.98).diffV2(reference, candidate)?.0)
      }

      // [#673](https://github.com/pointfreeco/swift-snapshot-testing/issues/673): read as linear,
      // one 8-bit step near black is about ΔE 3.5, so perceptual comparisons must not round this
      // smaller difference (about ΔE 2.5) up to a whole step. 0.97 allows ΔE 3.
      func testNearBlackSubStepDifferenceIsWithinPerceptualPrecision() throws {
        let reference = try image(.displayP3SixteenBit, [CGFloat](repeating: 1.3 / 255, count: 3))
        let candidate = try image(.extendedSRGBHalfFloat, [CGFloat](repeating: 2 / 255, count: 3))
        XCTAssertNotNil(
          imageDiffing().diffV2(reference, candidate), "Reaches the perceptual comparison")
        XCTAssertNil(
          imageDiffing(precision: 1, perceptualPrecision: 0.97).diffV2(reference, candidate)?.0)
      }

      private func imageDiffing(precision: Float = 1, perceptualPrecision: Float = 1)
        -> Diffing<UIImage>
      {
        .image(precision: precision, perceptualPrecision: perceptualPrecision, scale: 1)
      }

      private func image(_ layout: Layout, _ fill: [CGFloat], changedPixel: [CGFloat]? = nil)
        throws -> UIImage
      {
        UIImage(
          cgImage: try cgImage(layout, fill, changedPixel: changedPixel), scale: 1, orientation: .up
        )
      }
    #else
      private func imageDiffing(precision: Float = 1, perceptualPrecision: Float = 1)
        -> Diffing<NSImage>
      {
        .image(precision: precision, perceptualPrecision: perceptualPrecision)
      }

      private func image(_ layout: Layout, _ fill: [CGFloat], changedPixel: [CGFloat]? = nil)
        throws -> NSImage
      {
        NSImage(
          cgImage: try cgImage(layout, fill, changedPixel: changedPixel),
          size: NSSize(width: 16, height: 16))
      }
    #endif

    private enum Layout {
      case sRGB, displayP3, displayP3SixteenBit
      /// The format UIKit renders on wide-gamut devices.
      case extendedSRGBHalfFloat
    }

    /// A 16 × 16 image of `fill`, with one pixel set to `changedPixel`. Colors are sRGB red, green
    /// and blue components.
    private func cgImage(_ layout: Layout, _ fill: [CGFloat], changedPixel: [CGFloat]? = nil)
      throws -> CGImage
    {
      let alpha = CGImageAlphaInfo.premultipliedLast.rawValue
      let sixteenBit = alpha | CGBitmapInfo.byteOrder16Little.rawValue
      let (name, bitsPerComponent, bitmapInfo): (CFString, Int, UInt32) =
        switch layout {
        case .sRGB: (CGColorSpace.sRGB, 8, alpha)
        case .displayP3: (CGColorSpace.displayP3, 8, alpha)
        case .displayP3SixteenBit: (CGColorSpace.displayP3, 16, sixteenBit)
        case .extendedSRGBHalfFloat:
          (CGColorSpace.extendedSRGB, 16, sixteenBit | CGBitmapInfo.floatComponents.rawValue)
        }
      let context = try XCTUnwrap(
        CGContext(
          data: nil, width: 16, height: 16, bitsPerComponent: bitsPerComponent, bytesPerRow: 0,
          space: XCTUnwrap(CGColorSpace(name: name)), bitmapInfo: bitmapInfo))
      context.setFillColor(CGColor(srgbRed: fill[0], green: fill[1], blue: fill[2], alpha: 1))
      context.fill(CGRect(x: 0, y: 0, width: 16, height: 16))
      if let changedPixel {
        context.setFillColor(
          CGColor(srgbRed: changedPixel[0], green: changedPixel[1], blue: changedPixel[2], alpha: 1)
        )
        context.fill(CGRect(x: 8, y: 8, width: 1, height: 1))
      }
      return try XCTUnwrap(context.makeImage())
    }
  }
#endif
