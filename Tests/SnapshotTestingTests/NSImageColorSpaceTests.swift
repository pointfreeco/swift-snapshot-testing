#if os(macOS)
  import AppKit
  import SnapshotTesting
  import XCTest

  final class NSImageColorSpaceTests: XCTestCase {
    // Components that are exact at 8 bits, so every depth holds the same colors.
    private let blue: [CGFloat] = [0.2, 0.4, 0.6, 1]
    private let pink: [CGFloat] = [0.8, 0.4, 0.6, 1]
    private let white: [CGFloat] = [1, 1, 1, 1]
    private let black: [CGFloat] = [0, 0, 0, 1]
    private let bounds = CGRect(x: 0, y: 0, width: 16, height: 16)
    private let firstPixel = CGRect(x: 0, y: 0, width: 1, height: 1)

    // [#1083](https://github.com/pointfreeco/swift-snapshot-testing/issues/1083): images in
    // different colorspaces or bit depths compared their own bytes, so the same colors never
    // matched.
    func testSameColorsMatchAcrossColorSpacesAndBitDepths() throws {
      let pairs: [((CFString, Int), (CFString, Int))] = [
        ((CGColorSpace.sRGB, 8), (CGColorSpace.displayP3, 16)),
        ((CGColorSpace.sRGB, 8), (CGColorSpace.displayP3, 8)),
        ((CGColorSpace.sRGB, 8), (CGColorSpace.sRGB, 16)),
        ((CGColorSpace.sRGB, 16), (CGColorSpace.sRGB, 8)),
        ((CGColorSpace.displayP3, 8), (CGColorSpace.sRGB, 8)),
      ]
      for ((referenceSpace, referenceDepth), (snapshotSpace, snapshotDepth)) in pairs {
        let label =
          "\(referenceDepth)-bit \(referenceSpace) vs \(snapshotDepth)-bit \(snapshotSpace)"
        let reference = try recorded(
          image(in: referenceSpace, bitsPerComponent: referenceDepth, fills: [(blue, bounds)]))
        let snapshot = try image(
          in: snapshotSpace, bitsPerComponent: snapshotDepth, fills: [(blue, bounds)])
        XCTAssertNil(Diffing<NSImage>.image.diffV2(reference, snapshot)?.0, label)
      }
    }

    // [#1083](https://github.com/pointfreeco/swift-snapshot-testing/issues/1083): the precision
    // count read the reference's and snapshot's raw bytes as if they shared a layout, so a
    // one-pixel change reported a precision near 0.
    func testOnePixelChangeAcrossColorSpacesCountsOnlyThatPixel() throws {
      let reference = try recorded(
        image(in: CGColorSpace.sRGB, bitsPerComponent: 8, fills: [(blue, bounds)]))
      let snapshot = try image(
        in: CGColorSpace.displayP3, bitsPerComponent: 16,
        fills: [(blue, bounds), (pink, firstPixel)])

      XCTAssertNil(Diffing<NSImage>.image(precision: 0.99).diffV2(reference, snapshot)?.0)
      // One red component, one byte, of 16 × 16 × 4.
      XCTAssertEqual(
        Diffing<NSImage>.image(precision: 0.9999).diffV2(reference, snapshot)?.0,
        "Actual image precision 0.99902344 is less than required 0.9999")
    }

    // The precision count read the reference's byte count from the snapshot's smaller bitmap, past
    // its end.
    func testShallowerSnapshotCountsOnlyItsOwnPixels() throws {
      let reference = try recorded(
        image(in: CGColorSpace.sRGB, bitsPerComponent: 16, fills: [(blue, bounds)]))
      let snapshot = try image(
        in: CGColorSpace.sRGB, bitsPerComponent: 8, fills: [(blue, bounds), (pink, firstPixel)])

      XCTAssertNil(Diffing<NSImage>.image(precision: 0.99).diffV2(reference, snapshot)?.0)
      // One 16-bit red component, two bytes, of 16 × 16 × 8.
      XCTAssertEqual(
        Diffing<NSImage>.image(precision: 0.9999).diffV2(reference, snapshot)?.0,
        "Actual image precision 0.99902344 is less than required 0.9999")
    }

    // The byte comparisons covered only the reference's byte count of a deeper snapshot: its top
    // half.
    func testDeeperSnapshotIsComparedInFull() throws {
      let reference = try recorded(
        image(in: CGColorSpace.sRGB, bitsPerComponent: 8, fills: [(white, bounds)]))
      let snapshot = try image(
        in: CGColorSpace.sRGB, bitsPerComponent: 16,
        fills: [(white, bounds), (black, CGRect(x: 0, y: 0, width: 16, height: 8))])

      XCTAssertEqual(
        Diffing<NSImage>.image.diffV2(reference, snapshot)?.0,
        "Newly-taken snapshot does not match reference.")
    }

    // [#1083](https://github.com/pointfreeco/swift-snapshot-testing/issues/1083): perceptual
    // comparisons read Display P3 components as sRGB ones.
    func testPerceptualComparisonMatchesAcrossColorSpaces() throws {
      let red: [CGFloat] = [0.8, 0.2, 0.2, 1]
      // A changed pixel, so the comparison reaches the perceptual path.
      let nudged: [CGFloat] = [0.8, 0.2 + 2 / 255, 0.2, 1]
      let reference = try recorded(
        image(in: CGColorSpace.sRGB, bitsPerComponent: 8, fills: [(red, bounds)]))
      let snapshot = try image(
        in: CGColorSpace.displayP3, bitsPerComponent: 16,
        fills: [(red, bounds), (nudged, firstPixel)])

      XCTAssertNil(
        Diffing<NSImage>.image(precision: 0.99, perceptualPrecision: 0.98)
          .diffV2(reference, snapshot)?.0)
    }

    // Measured unmanaged, the Display P3 reference's components would read as linear sRGB, which
    // inflates dark differences past ΔE 2.
    func testPerceptualComparisonAcrossColorSpacesMeasuresActualColors() throws {
      let gray: [CGFloat] = [5 / 255, 5 / 255, 5 / 255, 1]
      let darker: [CGFloat] = [3 / 255, 3 / 255, 3 / 255, 1]
      let reference = try recorded(
        image(in: CGColorSpace.displayP3, bitsPerComponent: 8, fills: [(gray, bounds)]))
      let snapshot = try image(
        in: CGColorSpace.sRGB, bitsPerComponent: 8, fills: [(darker, bounds)])

      XCTAssertNil(
        Diffing<NSImage>.image(precision: 1, perceptualPrecision: 0.98)
          .diffV2(reference, snapshot)?.0)
    }

    // PNG encoding renames some colorspaces without changing their colors: DeviceRGB, like the
    // screen colorspaces layer and path snapshots draw in, decodes as another. Compared with the
    // unencoded snapshot, they looked like different colorspaces and lost the unmanaged measure.
    func testPerceptualComparisonOfEncoderRenamedColorSpaceKeepsUnmanagedMeasure() throws {
      // Dark grays 18 and 22: unmanaged ΔE is about 3.3, linear ΔE about 1.8, so only the unmanaged
      // measure fails at 0.98 (ΔE 2) and passes at 0.96 (ΔE 4).
      func deviceRGBImage(gray: CGFloat) throws -> NSImage {
        let context = try XCTUnwrap(
          CGContext(
            data: nil, width: 16, height: 16, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(red: gray, green: gray, blue: gray, alpha: 1)
        context.fill(bounds)
        return NSImage(cgImage: try XCTUnwrap(context.makeImage()), size: bounds.size)
      }
      let reference = try recorded(deviceRGBImage(gray: 18 / 255))
      let snapshot = try deviceRGBImage(gray: 22 / 255)
      XCTAssertNotEqual(
        reference.cgImage(forProposedRect: nil, context: nil, hints: nil)?.colorSpace,
        snapshot.cgImage(forProposedRect: nil, context: nil, hints: nil)?.colorSpace)

      XCTAssertNotNil(
        Diffing<NSImage>.image(precision: 0.9, perceptualPrecision: 0.98)
          .diffV2(reference, snapshot))
      XCTAssertNil(
        Diffing<NSImage>.image(precision: 0.9, perceptualPrecision: 0.96)
          .diffV2(reference, snapshot)?.0)
    }

    // References that decode as grayscale can't be drawn as RGBA in their own colorspace, so
    // every comparison with them failed to load the reference.
    func testGrayscaleReferenceIsComparedInSRGB() throws {
      let gray = try XCTUnwrap(CGColorSpace(name: CGColorSpace.genericGrayGamma2_2))
      let context = try XCTUnwrap(
        CGContext(
          data: nil, width: 16, height: 16, bitsPerComponent: 8, bytesPerRow: 0, space: gray,
          bitmapInfo: CGImageAlphaInfo.none.rawValue))
      context.setFillColor(gray: 1, alpha: 1)
      context.fill(bounds)
      let reference = try recorded(
        NSImage(cgImage: try XCTUnwrap(context.makeImage()), size: NSSize(width: 16, height: 16)))
      XCTAssertEqual(
        reference.cgImage(forProposedRect: nil, context: nil, hints: nil)?.colorSpace?.model,
        .monochrome)

      XCTAssertNil(
        Diffing<NSImage>.image.diffV2(
          reference, try image(in: CGColorSpace.sRGB, bitsPerComponent: 8, fills: [(white, bounds)])
        )?.0)
      XCTAssertEqual(
        Diffing<NSImage>.image.diffV2(
          reference,
          try image(
            in: CGColorSpace.sRGB, bitsPerComponent: 8,
            fills: [(white, bounds), (black, firstPixel)])
        )?.0,
        "Newly-taken snapshot does not match reference.")
    }

    private func image(
      in colorSpace: CFString, bitsPerComponent: Int, fills: [([CGFloat], CGRect)]
    ) throws -> NSImage {
      let sRGB = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
      let context = try XCTUnwrap(
        CGContext(
          data: nil, width: 16, height: 16, bitsPerComponent: bitsPerComponent, bytesPerRow: 0,
          space: XCTUnwrap(CGColorSpace(name: colorSpace)),
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
      for (components, rect) in fills {
        context.setFillColor(try XCTUnwrap(CGColor(colorSpace: sRGB, components: components)))
        context.fill(rect)
      }
      let cgImage = try XCTUnwrap(context.makeImage())
      return NSImage(cgImage: cgImage, size: NSSize(width: 16, height: 16))
    }

    private func recorded(_ image: NSImage) throws -> NSImage {
      try Diffing<NSImage>.image.fromData(Diffing<NSImage>.image.toData(image))
    }
  }
#endif
