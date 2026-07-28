#if os(macOS)
  import AppKit
  import XCTest

  @testable import SnapshotTesting

  final class NSImagePixelFormatTests: XCTestCase {
    private let convertingFormats:
      [(SnapshotTestingConfiguration.ImagePixelFormat, CFString, Int)] = [
        (.sRGB, CGColorSpace.sRGB, 8),
        (.sRGB(bitDepth: .sixteen), CGColorSpace.sRGB, 16),
        (.displayP3, CGColorSpace.displayP3, 8),
        (.displayP3(bitDepth: .sixteen), CGColorSpace.displayP3, 16),
      ]
    private let blue: [CGFloat] = [0.2, 0.4, 0.6, 1]

    // PNG IHDR fields: after the 8-byte signature and the chunk's 4-byte length and type, its data
    // holds a 4-byte width and height, then the bit depth and color type (2 RGB, 6 RGBA).
    private let bitDepthOffset = 24
    private let colorTypeOffset = 25

    func testConvertingFormatsRecordAndVerify() throws {
      // 16 × 16 pixels in 8 × 8 points.
      let snapshot = try makeImage(CGColorSpace.sRGB, blue, pointSize: 8)
      for (pixelFormat, colorSpace, bitsPerComponent) in convertingFormats {
        let label = String(describing: pixelFormat)
        let directory = try temporaryDirectory()
        withSnapshotTesting(imagePixelFormat: pixelFormat) {
          XCTAssertNotNil(
            verifySnapshot(
              of: snapshot, as: .image, named: "image", record: .all,
              snapshotDirectory: directory),
            "Record mode reports the recorded snapshot: \(label)")
          XCTAssertNil(
            verifySnapshot(
              of: snapshot, as: .image, named: "image", record: .never,
              snapshotDirectory: directory),
            label)
        }

        let png = try referenceData(in: directory)
        XCTAssertEqual(Int(png[bitDepthOffset]), bitsPerComponent, "PNG IHDR bit depth: \(label)")
        XCTAssertEqual(png[colorTypeOffset], 2, "PNG IHDR color type RGB: \(label)")
        let reference = try XCTUnwrap(NSImage(data: png))
        XCTAssertEqual(reference.size, NSSize(width: 8, height: 8), label)
        let cgImage = try XCTUnwrap(
          reference.cgImage(forProposedRect: nil, context: nil, hints: nil))
        XCTAssertEqual(cgImage.width, 16, label)
        XCTAssertEqual(cgImage.colorSpace?.name, colorSpace, label)
        XCTAssertEqual(cgImage.bitsPerComponent, bitsPerComponent, label)
      }
    }

    func testTranslucentSnapshotsKeepAlpha() throws {
      let translucent = try makeImage(CGColorSpace.sRGB, [0.2, 0.4, 0.6, 0.5])
      for (pixelFormat, _, _) in convertingFormats {
        XCTAssertEqual(
          try recordedData(of: translucent, in: pixelFormat)[colorTypeOffset], 6,
          "PNG IHDR color type RGBA: \(pixelFormat)")
      }
    }

    func testAutomaticKeepsAppKitEncoding() throws {
      let image = try makeImage(CGColorSpace.sRGB, blue, pointSize: 8)
      XCTAssertIdentical(normalized(image, to: ImageComparisonFormat(.automatic)), image)
      let rep = NSBitmapImageRep(
        cgImage: try XCTUnwrap(image.cgImage(forProposedRect: nil, context: nil, hints: nil)))
      rep.size = image.size
      XCTAssertEqual(
        try recordedData(of: image, in: .automatic),
        rep.representation(using: .png, properties: [:])
      )
    }

    func testDisplayP3KeepsWideGamutColorsThatSRGBClips() throws {
      // Display P3 yellows about 28 ΔE76 apart that clip to the same sRGB color.
      let warmerComponents: [CGFloat] = [1, 1, 79 / 255, 1]
      let yellow = try makeImage(CGColorSpace.displayP3, [1, 1, 0, 1])
      let warmer = try makeImage(CGColorSpace.displayP3, warmerComponents)
      for (pixelFormat, colorSpace, _) in convertingFormats {
        let label = String(describing: pixelFormat)
        let reference = try recorded(yellow, in: pixelFormat)
        let failure = withSnapshotTesting(imagePixelFormat: pixelFormat) {
          Diffing<NSImage>.image.diffV2(reference, warmer)
        }
        if colorSpace == CGColorSpace.sRGB {
          XCTAssertNil(failure?.0, "Both yellows clip to the same sRGB color: \(label)")
        } else {
          XCTAssertNotNil(failure, label)
        }
      }
      // macOS compares automatic references in their own format, here Display P3.
      let reference = try recorded(yellow, in: .automatic)
      XCTAssertNotNil(Diffing<NSImage>.image.diffV2(reference, warmer))
    }

    func testPerceptualMeasureFollowsFormat() throws {
      // Dark grays 18 and 22: unmanaged ΔE is about 3.3, linear ΔE about 1.8, so only the unmanaged
      // measure fails at 0.98 (ΔE 2) and passes at 0.96 (ΔE 4).
      let grayComponents: [CGFloat] = [18 / 255, 18 / 255, 18 / 255, 1]
      let lighterComponents: [CGFloat] = [22 / 255, 22 / 255, 22 / 255, 1]
      let gray = try makeImage(CGColorSpace.sRGB, grayComponents)
      let lighter = try makeImage(CGColorSpace.sRGB, lighterComponents)
      for pixelFormat in [.automatic, .sRGB, .sRGB(bitDepth: .sixteen)]
        as [SnapshotTestingConfiguration.ImagePixelFormat]
      {
        let label = String(describing: pixelFormat)
        let reference = try recorded(gray, in: pixelFormat)
        withSnapshotTesting(imagePixelFormat: pixelFormat) {
          XCTAssertNotNil(
            Diffing<NSImage>.image(precision: 0.9, perceptualPrecision: 0.98)
              .diffV2(reference, lighter), label)
          XCTAssertNil(
            Diffing<NSImage>.image(precision: 0.9, perceptualPrecision: 0.96)
              .diffV2(reference, lighter)?.0, label)
        }
      }
      let reference = try recorded(gray, in: .displayP3(bitDepth: .sixteen))
      withSnapshotTesting(imagePixelFormat: .displayP3(bitDepth: .sixteen)) {
        XCTAssertNil(
          Diffing<NSImage>.image(precision: 0.9, perceptualPrecision: 0.98)
            .diffV2(reference, lighter)?.0, "Display P3 measures the actual color difference")
      }
    }

    func testSixteenBitPrecisionCountsComponents() throws {
      // 8 of 1,024 components change by one in their low byte: 0.78% of components, 0.39% of
      // bytes.
      let reference = try makeSixteenBitDisplayP3Image(changedPixels: 0)
      let candidate = try makeSixteenBitDisplayP3Image(changedPixels: 8)
      withSnapshotTesting(imagePixelFormat: .displayP3(bitDepth: .sixteen)) {
        XCTAssertNil(Diffing<NSImage>.image(precision: 0.99).diffV2(reference, candidate))
        XCTAssertEqual(
          Diffing<NSImage>.image(precision: 0.995).diffV2(reference, candidate)?.0,
          "Actual image precision 0.9921875 is less than required 0.995")
      }
    }

    /// A 16 × 16 pixel 8-bit image filled with `components` in `colorSpace`.
    private func makeImage(
      _ colorSpace: CFString, _ components: [CGFloat], pointSize: CGFloat = 16
    ) throws -> NSImage {
      let space = try XCTUnwrap(CGColorSpace(name: colorSpace))
      let context = try XCTUnwrap(
        CGContext(
          data: nil, width: 16, height: 16, bitsPerComponent: 8, bytesPerRow: 0, space: space,
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
      context.setFillColor(try XCTUnwrap(CGColor(colorSpace: space, components: components)))
      context.fill(CGRect(x: 0, y: 0, width: 16, height: 16))
      return NSImage(
        cgImage: try XCTUnwrap(context.makeImage()),
        size: NSSize(width: pointSize, height: pointSize))
    }

    /// A 16 × 16 16-bit Display P3 image whose first `changedPixels` pixels have red raised by one
    /// in the low byte.
    private func makeSixteenBitDisplayP3Image(changedPixels: Int) throws -> NSImage {
      // Mid-gray RGBA: 0x8000 is half of the 16-bit range, index 3 is alpha and index 0 red.
      var components = [UInt16](repeating: 0x8000, count: 16 * 16 * 4)
      for pixel in 0..<(16 * 16) {
        components[pixel * 4 + 3] = .max
        if pixel < changedPixels { components[pixel * 4] += 1 }
      }
      let data = components.withUnsafeBytes { Data($0) }
      let image = try XCTUnwrap(
        CGImage(
          width: 16, height: 16, bitsPerComponent: 16, bitsPerPixel: 64, bytesPerRow: 16 * 8,
          space: XCTUnwrap(CGColorSpace(name: CGColorSpace.displayP3)),
          bitmapInfo: CGBitmapInfo(
            rawValue: CGImageAlphaInfo.premultipliedLast.rawValue
              | CGBitmapInfo.byteOrder16Little.rawValue),
          provider: XCTUnwrap(CGDataProvider(data: data as CFData)), decode: nil,
          shouldInterpolate: false, intent: .defaultIntent))
      return NSImage(cgImage: image, size: NSSize(width: 16, height: 16))
    }

    private func recordedData(
      of image: NSImage, in pixelFormat: SnapshotTestingConfiguration.ImagePixelFormat
    ) throws -> Data {
      try withSnapshotTesting(imagePixelFormat: pixelFormat) {
        try Diffing<NSImage>.image.toData(image)
      }
    }

    /// The reference `pixelFormat` records for `image`.
    private func recorded(
      _ image: NSImage, in pixelFormat: SnapshotTestingConfiguration.ImagePixelFormat
    ) throws -> NSImage {
      try Diffing<NSImage>.image.fromData(recordedData(of: image, in: pixelFormat))
    }

    private func temporaryDirectory() throws -> String {
      let directory = NSTemporaryDirectory() + "NSImagePixelFormatTests-" + UUID().uuidString
      addTeardownBlock { try? FileManager.default.removeItem(atPath: directory) }
      return directory
    }

    private func referenceData(in directory: String) throws -> Data {
      let name = try XCTUnwrap(
        FileManager.default.contentsOfDirectory(atPath: directory).first { $0.hasSuffix(".png") })
      return try Data(contentsOf: URL(fileURLWithPath: directory + "/" + name))
    }
  }
#endif
