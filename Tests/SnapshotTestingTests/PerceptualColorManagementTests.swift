#if os(iOS) || os(tvOS) || os(macOS)
  import CoreImage
  import XCTest

  @testable import SnapshotTesting

  final class PerceptualColorManagementTests: XCTestCase {
    func testSameColorInDifferentColorspacesMatches() throws {
      let red = try XCTUnwrap(
        CGColor(colorSpace: colorSpace(CGColorSpace.sRGB), components: [1, 0, 0, 1]))
      let srgb = try image(filledWith: red, in: CGColorSpace.sRGB)
      let displayP3 = try image(filledWith: red, in: CGColorSpace.displayP3)

      // Linear ΔE is about 0.08; a gamma-encoded working space would measure about 1.
      XCTAssertNil(
        perceptuallyCompare(
          srgb, displayP3, pixelPrecision: 1, perceptualPrecision: 0.995, colorManaged: true))
      XCTAssertNil(
        perceptuallyCompare(
          displayP3, srgb, pixelPrecision: 1, perceptualPrecision: 0.995, colorManaged: true))
    }

    func testDifferentColorsInDifferentColorspacesStillFail() throws {
      let red = try XCTUnwrap(
        CGColor(colorSpace: colorSpace(CGColorSpace.sRGB), components: [1, 0, 0, 1]))
      let orange = try XCTUnwrap(
        CGColor(colorSpace: colorSpace(CGColorSpace.sRGB), components: [1, 0.5, 0, 1]))

      XCTAssertNotNil(
        perceptuallyCompare(
          try image(filledWith: red, in: CGColorSpace.sRGB),
          try image(filledWith: orange, in: CGColorSpace.displayP3),
          pixelPrecision: 1, perceptualPrecision: 0.98, colorManaged: true))
    }

    func testSameColorspaceComparisonsKeepUnmanagedValues() throws {
      // Unmanaged ΔE is about 1.2 and linear ΔE about 2 for 128 vs 133 in one channel; 0.985 allows
      // ΔE 1.5 and 0.99 allows ΔE 1.
      for name in [CGColorSpace.sRGB, CGColorSpace.displayP3] {
        let space = try colorSpace(name)
        let gray = try XCTUnwrap(CGColor(colorSpace: space, components: [0.5, 0.5, 0.5, 1]))
        let lighter = try XCTUnwrap(CGColor(colorSpace: space, components: [0.52, 0.5, 0.5, 1]))
        let old = try image(filledWith: gray, in: name)
        let new = try image(filledWith: lighter, in: name)

        XCTAssertNil(
          perceptuallyCompare(
            old, new, pixelPrecision: 1, perceptualPrecision: 0.985, colorManaged: false),
          "\(name)")
        XCTAssertNotNil(
          perceptuallyCompare(
            old, new, pixelPrecision: 1, perceptualPrecision: 0.99, colorManaged: false),
          "\(name)")
        XCTAssertNotNil(
          perceptuallyCompare(
            old, new, pixelPrecision: 1, perceptualPrecision: 0.985, colorManaged: true),
          "\(name)")
      }
    }

    private func colorSpace(_ name: CFString) throws -> CGColorSpace {
      try XCTUnwrap(CGColorSpace(name: name))
    }

    private func image(filledWith color: CGColor, in name: CFString) throws -> CIImage {
      let context = try XCTUnwrap(
        CGContext(
          data: nil, width: 8, height: 8, bitsPerComponent: 8, bytesPerRow: 0,
          space: colorSpace(name), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
      context.setFillColor(color)
      context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
      return CIImage(cgImage: try XCTUnwrap(context.makeImage()))
    }
  }
#endif
