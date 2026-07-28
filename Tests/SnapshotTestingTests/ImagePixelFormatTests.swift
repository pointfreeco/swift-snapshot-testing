#if os(iOS) || os(tvOS)
  import SwiftUI
  import UIKit
  import XCTest

  @_spi(Internals) @testable import SnapshotTesting

  final class ImagePixelFormatTests: XCTestCase {
    private let displayP3Formats: [(SnapshotTestingConfiguration.ImagePixelFormat, Int)] = [
      (.displayP3, 8),
      (.displayP3(bitDepth: .sixteen), 16),
    ]
    private let convertingFormats:
      [(SnapshotTestingConfiguration.ImagePixelFormat, CFString, Int)] = [
        (.sRGB, CGColorSpace.sRGB, 8),
        (.sRGB(bitDepth: .sixteen), CGColorSpace.sRGB, 16),
        (.displayP3, CGColorSpace.displayP3, 8),
        (.displayP3(bitDepth: .sixteen), CGColorSpace.displayP3, 16),
      ]

    // PNG IHDR fields: after the 8-byte signature and the chunk's 4-byte length and type, its data
    // holds a 4-byte width and height, then the bit depth and color type (2 RGB, 6 RGBA).
    private let bitDepthOffset = 24
    private let colorTypeOffset = 25

    func testConvertingFormatsRecordAndVerify() throws {
      for (pixelFormat, colorSpace, bitsPerComponent) in convertingFormats {
        let directory = try temporaryDirectory()
        let strategy = Snapshotting<UIView, UIImage>.image(precision: 1, perceptualPrecision: 1)

        withSnapshotTesting(imagePixelFormat: pixelFormat) {
          XCTAssertNotNil(
            verifySnapshot(
              of: fixtureView(), as: strategy, named: "fixture", record: .all,
              snapshotDirectory: directory),
            "Record mode reports the recorded snapshot")
          XCTAssertNil(
            verifySnapshot(
              of: fixtureView(), as: strategy, named: "fixture", record: .never,
              snapshotDirectory: directory))
        }

        let png = try referenceData(in: directory)
        XCTAssertEqual(Int(png[bitDepthOffset]), bitsPerComponent, "PNG IHDR bit depth")
        let reference = try XCTUnwrap(UIImage(data: png)?.cgImage)
        XCTAssertEqual(reference.colorSpace?.name, colorSpace)
        XCTAssertEqual(reference.bitsPerComponent, bitsPerComponent)

        // Red top-left and blue bottom-right corners catch coordinate flips in the conversion.
        let topLeft = try pixel(of: reference, x: 2, y: 2)
        let bottomRight = try pixel(of: reference, x: reference.width - 3, y: reference.height - 3)
        XCTAssertGreaterThan(topLeft.red, 150)
        XCTAssertLessThan(topLeft.blue, 100)
        XCTAssertGreaterThan(bottomRight.blue, 150)
        XCTAssertLessThan(bottomRight.red, 100)
      }
    }

    func testConvertingFormatsExactMatchComparesWithoutColorConversion() throws {
      for (pixelFormat, _, _) in convertingFormats {
        let format = ImageComparisonFormat(pixelFormat)
        let snapshot = normalized(try capture(fixtureView()), to: format)
        let reference = try XCTUnwrap(UIImage(data: XCTUnwrap(snapshot.pngData())))

        // Both sides already have the comparison context's colorspace and depth, so drawing them
        // into it only copies components.
        XCTAssertTrue(format.isRepresentation(of: try XCTUnwrap(snapshot.cgImage)))
        XCTAssertTrue(format.isRepresentation(of: try XCTUnwrap(reference.cgImage)))
        XCTAssertEqual(
          try comparisonBytes(of: snapshot, format: format),
          try comparisonBytes(of: reference, format: format),
          "A reference decodes to the snapshot's exact comparison bytes")
      }
    }

    func testOpaqueSnapshotsRecordWithoutAlpha() throws {
      let strategy = Snapshotting<UIView, UIImage>.image(precision: 1, perceptualPrecision: 1)
      for (pixelFormat, colorSpace, bitsPerComponent) in convertingFormats {
        let label = String(describing: pixelFormat)
        let directory = try temporaryDirectory()
        withSnapshotTesting(imagePixelFormat: pixelFormat) {
          _ = verifySnapshot(
            of: fixtureView(), as: strategy, named: "opaque", record: .all,
            snapshotDirectory: directory)
          XCTAssertNil(
            verifySnapshot(
              of: fixtureView(), as: strategy, named: "opaque", record: .never,
              snapshotDirectory: directory),
            label)
        }
        let png = try referenceData(in: directory)
        XCTAssertEqual(png[colorTypeOffset], 2, "PNG IHDR color type RGB: \(label)")
        XCTAssertEqual(Int(png[bitDepthOffset]), bitsPerComponent, label)
        let reference = try XCTUnwrap(UIImage(data: png)?.cgImage)
        XCTAssertEqual(reference.colorSpace?.name, colorSpace, label)
        // Decoding the RGB reference into the comparison context restores its exact bytes.
        let format = ImageComparisonFormat(pixelFormat)
        XCTAssertEqual(
          try comparisonBytes(of: UIImage(cgImage: reference), format: format),
          try comparisonBytes(of: normalized(capture(fixtureView()), to: format), format: format),
          label)
      }
    }

    func testTranslucentSnapshotsKeepAlpha() throws {
      let strategy = Snapshotting<UIView, UIImage>.image(precision: 1, perceptualPrecision: 1)
      let translucentView = { () -> UIView in
        let view = self.fixtureView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        return view
      }
      for (pixelFormat, _, _) in convertingFormats {
        let label = String(describing: pixelFormat)
        let directory = try temporaryDirectory()
        withSnapshotTesting(imagePixelFormat: pixelFormat) {
          _ = verifySnapshot(
            of: translucentView(), as: strategy, named: "translucent", record: .all,
            snapshotDirectory: directory)
          XCTAssertNil(
            verifySnapshot(
              of: translucentView(), as: strategy, named: "translucent", record: .never,
              snapshotDirectory: directory),
            label)
        }
        XCTAssertEqual(
          try referenceData(in: directory)[colorTypeOffset], 6,
          "PNG IHDR color type RGBA: \(label)")
      }
    }

    func testOpaqueReferenceCatchesTranslucentChange() throws {
      let fill = Color.sRGB(red: 0.2, green: 0.4, blue: 0.6)
      for (pixelFormat, _, _) in convertingFormats {
        let label = String(describing: pixelFormat)
        let reference = try recordedReference(of: try makeImage(fill), in: pixelFormat)
        let alphaInfo = try XCTUnwrap(reference.cgImage?.alphaInfo)
        XCTAssertTrue(
          [CGImageAlphaInfo.none, .noneSkipFirst, .noneSkipLast].contains(alphaInfo),
          "The reference has no alpha: \(label)")
        let candidate = try makeImage(fill, changedPixel: .clear)
        withSnapshotTesting(imagePixelFormat: pixelFormat) {
          XCTAssertNotNil(Diffing<UIImage>.image(scale: 1).diffV2(reference, candidate), label)
        }
      }
    }

    func testConvertingFormatsCompareSymbolImagesAsDrawn() throws {
      let star = try XCTUnwrap(UIImage(systemName: "star.fill"))
      for (pixelFormat, _, _) in convertingFormats {
        let label = String(describing: pixelFormat)
        let reference = try recordedReference(of: star.withTintColor(.red), in: pixelFormat)
        withSnapshotTesting(imagePixelFormat: pixelFormat) {
          let diffing = Diffing<UIImage>.image(scale: 1)
          XCTAssertNil(diffing.diffV2(reference, star.withTintColor(.red))?.0, label)
          XCTAssertNotNil(diffing.diffV2(reference, star.withTintColor(.blue)), label)
        }
      }
    }

    func testAutomaticKeepsUIKitEncoding() throws {
      let image = try makeImage(.sRGB(red: 0.2, green: 0.4, blue: 0.6))
      let diffing = Diffing<UIImage>.image(scale: 1)
      try withSnapshotTesting(imagePixelFormat: .automatic) {
        XCTAssertEqual(try diffing.toData(image), image.pngData())
      }
    }

    func testAutomaticDoesNotConvertSnapshots() throws {
      let snapshot = try capture(fixtureView())
      XCTAssertIdentical(normalized(snapshot, to: ImageComparisonFormat(nil)), snapshot)
      XCTAssertIdentical(normalized(snapshot, to: ImageComparisonFormat(.automatic)), snapshot)
    }

    func testNormalizationKeepsPixelSizeScaleAndOrientation() throws {
      let source = try makeImage(.sRGB(red: 1, green: 0, blue: 0), width: 25, height: 13)
      let image = UIImage(cgImage: try XCTUnwrap(source.cgImage), scale: 2.608, orientation: .right)

      for (pixelFormat, colorSpace, bitsPerComponent) in convertingFormats {
        let converted = normalized(image, to: ImageComparisonFormat(pixelFormat))
        let cgImage = try XCTUnwrap(converted.cgImage)
        XCTAssertEqual(cgImage.width, 25)
        XCTAssertEqual(cgImage.height, 13)
        XCTAssertEqual(cgImage.bitsPerComponent, bitsPerComponent)
        XCTAssertEqual(cgImage.colorSpace?.name, colorSpace)
        XCTAssertEqual(converted.scale, 2.608)
        XCTAssertEqual(converted.imageOrientation, .right)
      }
    }

    func testLayerAndPathStrategiesRecordInConvertingFormats() throws {
      let layer = CALayer()
      layer.frame = CGRect(x: 0, y: 0, width: 8, height: 8)
      layer.backgroundColor = UIColor.red.cgColor
      let path = CGPath(rect: CGRect(x: 0, y: 0, width: 8, height: 8), transform: nil)

      for (pixelFormat, colorSpace, bitsPerComponent) in convertingFormats {
        let directory = try temporaryDirectory()
        withSnapshotTesting(imagePixelFormat: pixelFormat) {
          _ = verifySnapshot(
            of: layer, as: .image, named: "layer", record: .all, snapshotDirectory: directory)
          _ = verifySnapshot(
            of: path, as: .image, named: "path", record: .all, snapshotDirectory: directory)
        }
        let names = try FileManager.default.contentsOfDirectory(atPath: directory).sorted()
        XCTAssertEqual(
          names,
          [
            "testLayerAndPathStrategiesRecordInConvertingFormats.layer.png",
            "testLayerAndPathStrategiesRecordInConvertingFormats.path.png",
          ],
          String(describing: pixelFormat))
        for name in names {
          let reference = try XCTUnwrap(
            UIImage(contentsOfFile: directory + "/" + name)?.cgImage, name)
          XCTAssertEqual(reference.colorSpace?.name, colorSpace, name)
          XCTAssertEqual(reference.bitsPerComponent, bitsPerComponent, name)
        }
      }
    }

    // [#1083](https://github.com/pointfreeco/swift-snapshot-testing/issues/1083): a Display P3
    // reference compared with an extended sRGB snapshot reported every pixel as mismatched.
    func testPerceptualComparisonMatchesNudgedPixelInEachFormat() throws {
      let fill = Color.displayP3(red: 0.9, green: 0.4, blue: 0.1)
      // Two 8-bit steps, so the change survives 8-bit quantization in every format.
      let nudged = Color.displayP3(red: 0.9, green: 0.4 + 2 / 255, blue: 0.1)
      let candidate = try makeImage(fill, changedPixel: nudged)
      let recolored = try makeImage(.sRGB(red: 0, green: 1, blue: 0))

      for pixelFormat in [nil, .automatic] + convertingFormats.map(\.0) {
        let label = String(describing: pixelFormat)
        let reference = try recordedReference(of: try makeImage(fill), in: pixelFormat)
        withSnapshotTesting(imagePixelFormat: pixelFormat) {
          XCTAssertNotNil(
            Diffing<UIImage>.image(scale: 1).diffV2(reference, candidate),
            "The nudged pixel must reach the perceptual comparison: \(label)")
          let diffing = Diffing<UIImage>.image(precision: 1, perceptualPrecision: 0.98, scale: 1)
          XCTAssertNil(diffing.diffV2(reference, candidate)?.0, label)
          XCTAssertNotNil(diffing.diffV2(reference, recolored), label)
        }
      }
    }

    // [#1127](https://github.com/pointfreeco/swift-snapshot-testing/issues/1127): a one-pixel
    // change reported as a mismatch of every pixel. One of the 100 pixels changes by more than
    // perceptualPrecision allows, so it fails at precision 1 and passes at 0.98.
    func testOnePixelChangeMatchesWithinPrecisionInEitherColorspace() throws {
      for pixelFormat in [nil, .automatic] + convertingFormats.map(\.0) {
        for colorSpace in [SwiftUI.Color.RGBColorSpace.displayP3, .sRGB] {
          let label = "\(String(describing: pixelFormat)), \(colorSpace)"
          let purple = SwiftUI.Color(colorSpace, red: 0.5, green: 0, blue: 1)
          let shiftedPurple = SwiftUI.Color(colorSpace, red: 0.7, green: 0, blue: 1)
          let directory = try temporaryDirectory()
          let snapshot = {
            (
              firstSquare: SwiftUI.Color, precision: Float,
              record: SnapshotTestingConfiguration.Record
            )
            in
            verifySnapshot(
              of: UIHostingController(
                rootView: ZStack(alignment: .topLeading) {
                  purple
                  firstSquare.frame(width: 1, height: 1)
                }
              ),
              as: .image(
                precision: precision,
                perceptualPrecision: 0.99,
                size: CGSize(width: 10, height: 10),
                traits: UITraitCollection(displayScale: 1)
              ),
              named: "\(colorSpace)",
              record: record,
              snapshotDirectory: directory,
              testName: "squares"
            )
          }
          withSnapshotTesting(imagePixelFormat: pixelFormat) {
            _ = snapshot(purple, 1, .all)
            XCTAssertNil(snapshot(shiftedPurple, 0.98, .never), label)
            XCTAssertNotNil(snapshot(shiftedPurple, 1, .never), label)
          }
        }
      }
    }

    func testDisplayP3KeepsWideGamutColorsThatAutomaticClips() throws {
      // Display P3 yellows about 28 ΔE76 apart that clip to the same sRGB color.
      let yellow = Color.displayP3(red: 1, green: 1, blue: 0)
      let warmer = Color.displayP3(red: 1, green: 1, blue: 79 / 255)

      for pixelFormat in [.automatic, .sRGB, .sRGB(bitDepth: .sixteen)] + displayP3Formats.map(\.0)
      {
        let label = String(describing: pixelFormat)
        let reference = try recordedReference(of: try makeImage(yellow), in: pixelFormat)
        let candidate = try makeImage(warmer)
        try withSnapshotTesting(imagePixelFormat: pixelFormat) {
          let failure = Diffing<UIImage>.image(scale: 1).diffV2(reference, candidate)
          if [.automatic, .sRGB, .sRGB(bitDepth: .sixteen)].contains(pixelFormat) {
            XCTAssertNil(failure, "Both yellows clip to the same sRGB color: \(label)")
          } else {
            let blue = try pixel(of: XCTUnwrap(reference.cgImage), x: 8, y: 8).blue
            XCTAssertLessThan(blue, 5, "The reference keeps P3 yellow: \(label)")
            XCTAssertNotNil(failure, label)
          }
        }
      }
    }

    func testSRGBKeepsAutomaticPerceptualMeasure() throws {
      // Dark grays 18 and 22: unmanaged ΔE is about 3.3, linear ΔE about 1.8, so only the unmanaged
      // measure fails at 0.98 (ΔE 2) and passes at 0.96 (ΔE 4).
      let gray = Color.sRGB(red: 18 / 255, green: 18 / 255, blue: 18 / 255)
      let candidate = try makeImage(.sRGB(red: 22 / 255, green: 22 / 255, blue: 22 / 255))
      for pixelFormat in [.automatic, .sRGB, .sRGB(bitDepth: .sixteen)]
        as [SnapshotTestingConfiguration.ImagePixelFormat]
      {
        let label = String(describing: pixelFormat)
        let reference = try recordedReference(of: try makeImage(gray), in: pixelFormat)
        withSnapshotTesting(imagePixelFormat: pixelFormat) {
          XCTAssertNotNil(
            Diffing<UIImage>.image(precision: 0.9, perceptualPrecision: 0.98, scale: 1)
              .diffV2(reference, candidate), label)
          XCTAssertNil(
            Diffing<UIImage>.image(precision: 0.9, perceptualPrecision: 0.96, scale: 1)
              .diffV2(reference, candidate)?.0, label)
        }
      }
    }

    func testSixteenBitKeepsDifferencesThatEightBitMerges() throws {
      // Both greens share one 8-bit Display P3 code.
      let green = try makeImage(.sRGB(red: 12 / 255, green: 1, blue: 0))
      let shifted = try makeImage(.sRGB(red: 15 / 255, green: 1, blue: 0))

      for (pixelFormat, bitsPerComponent) in displayP3Formats {
        let reference = try recordedReference(of: green, in: pixelFormat)
        withSnapshotTesting(imagePixelFormat: pixelFormat) {
          let failure = Diffing<UIImage>.image(scale: 1).diffV2(reference, shifted)
          if bitsPerComponent == 8 {
            XCTAssertNil(failure, "8-bit Display P3 merges these sRGB colors")
          } else {
            XCTAssertNotNil(failure, "16-bit Display P3 keeps these sRGB colors distinct")
          }
        }
      }
    }

    func testSixteenBitSRGBKeepsDifferencesSmallerThanOneEightBitStep() throws {
      // 0.4 is 102.0 and the nudge 102.3 in 8-bit sRGB, so both round to the same code.
      let gray = try makeImage(.sRGB(red: 0.4, green: 0.4, blue: 0.4))
      let nudged = try makeImage(.sRGB(red: 0.4 + 0.3 / 255, green: 0.4, blue: 0.4))
      for (pixelFormat, bitsPerComponent) in [
        (SnapshotTestingConfiguration.ImagePixelFormat.sRGB, 8), (.sRGB(bitDepth: .sixteen), 16),
      ] {
        let reference = try recordedReference(of: gray, in: pixelFormat)
        withSnapshotTesting(imagePixelFormat: pixelFormat) {
          let failure = Diffing<UIImage>.image(scale: 1).diffV2(reference, nudged)
          if bitsPerComponent == 8 {
            XCTAssertNil(failure, "8-bit sRGB rounds the change away")
          } else {
            XCTAssertNotNil(failure, "16-bit sRGB keeps the change")
          }
        }
      }
    }

    func testSixteenBitPrecisionCountsComponents() throws {
      // 8 of 1,024 components change by one in their low byte: 0.78% of components, 0.39% of
      // bytes, 3.1% of pixels.
      let reference = try makeSixteenBitDisplayP3Image(changedPixels: 0)
      let candidate = try makeSixteenBitDisplayP3Image(changedPixels: 8)
      withSnapshotTesting(imagePixelFormat: .displayP3(bitDepth: .sixteen)) {
        XCTAssertNil(Diffing<UIImage>.image(precision: 0.99, scale: 1).diffV2(reference, candidate))
        XCTAssertNotNil(
          Diffing<UIImage>.image(precision: 0.995, scale: 1).diffV2(reference, candidate))
      }
    }

    // [#1097](https://github.com/pointfreeco/swift-snapshot-testing/issues/1097),
    // [#1111](https://github.com/pointfreeco/swift-snapshot-testing/issues/1111): difference images
    // read raw bitmaps as 8-bit RGBA.
    func testDifferenceImageSupportsSixteenBitReferences() throws {
      let red = Color.sRGB(red: 1, green: 0, blue: 0)
      let reference = try XCTUnwrap(UIImage(data: XCTUnwrap(makeImage(red).pngData()), scale: 1))
      XCTAssertEqual(reference.cgImage?.bitsPerComponent, 16)
      let candidate = try makeImage(red, changedPixel: .sRGB(red: 0, green: 0, blue: 1))

      for pixelFormat in [nil] + convertingFormats.map(\.0) {
        let label = String(describing: pixelFormat)
        try withSnapshotTesting(imagePixelFormat: pixelFormat) {
          let difference = try differenceImage(reference, candidate)
          // Component differences render as gray; the blend-mode fallback would render magenta.
          let changed = try pixel(of: difference, x: 8, y: 8)
          XCTAssertGreaterThan(changed.green, 200, label)
          XCTAssertLessThan(try pixel(of: difference, x: 2, y: 2).red, 50, label)
        }
      }
    }

    func testSixteenBitDifferenceImageShowsChangesBelowEightBits() throws {
      let pixelFormat = SnapshotTestingConfiguration.ImagePixelFormat.displayP3(bitDepth: .sixteen)
      let green = Color.sRGB(red: 12 / 255, green: 1, blue: 0)
      let reference = try recordedReference(of: try makeImage(green), in: pixelFormat)
      let candidate = try makeImage(green, changedPixel: .sRGB(red: 15 / 255, green: 1, blue: 0))

      try withSnapshotTesting(imagePixelFormat: pixelFormat) {
        let difference = try differenceImage(reference, candidate)
        XCTAssertGreaterThan(try pixel(of: difference, x: 8, y: 8).green, 200)
        XCTAssertLessThan(try pixel(of: difference, x: 2, y: 2).green, 50)
      }
    }

    // MARK: - Fixtures

    private enum Color {
      case sRGB(red: CGFloat, green: CGFloat, blue: CGFloat)
      case displayP3(red: CGFloat, green: CGFloat, blue: CGFloat)
      case clear

      var cgColor: CGColor {
        switch self {
        case .sRGB(let red, let green, let blue):
          return CGColor(srgbRed: red, green: green, blue: blue, alpha: 1)
        case .displayP3(let red, let green, let blue):
          return CGColor(
            colorSpace: CGColorSpace(name: CGColorSpace.displayP3)!,
            components: [red, green, blue, 1])!
        case .clear:
          return CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0)
        }
      }
    }

    /// A 16-bit half-float extended sRGB image, the format UIKit renders on wide-gamut devices,
    /// optionally with the pixel at (8, 8) recolored.
    private func makeImage(
      _ fill: Color, changedPixel: Color? = nil, width: Int = 16, height: Int = 16
    ) throws -> UIImage {
      let context = try XCTUnwrap(
        CGContext(
          data: nil, width: width, height: height, bitsPerComponent: 16, bytesPerRow: 0,
          space: XCTUnwrap(CGColorSpace(name: CGColorSpace.extendedSRGB)),
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            | CGBitmapInfo.byteOrder16Little.rawValue | CGBitmapInfo.floatComponents.rawValue))
      context.setFillColor(fill.cgColor)
      context.fill(CGRect(x: 0, y: 0, width: width, height: height))
      if let changedPixel {
        context.setBlendMode(.copy)
        context.setFillColor(changedPixel.cgColor)
        // Core Graphics' origin is bottom-left, so this is (8, 8) from the top-left.
        context.fill(CGRect(x: 8, y: height - 9, width: 1, height: 1))
      }
      return UIImage(cgImage: try XCTUnwrap(context.makeImage()), scale: 1, orientation: .up)
    }

    /// A 16 × 16 16-bit Display P3 image whose first `changedPixels` pixels have red raised by one
    /// in the low byte.
    private func makeSixteenBitDisplayP3Image(changedPixels: Int) throws -> UIImage {
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
      return UIImage(cgImage: image, scale: 1, orientation: .up)
    }

    private func fixtureView() -> UIView {
      let view = UIView(frame: CGRect(x: 0, y: 0, width: 120, height: 80))
      view.backgroundColor = .white
      for (frame, color) in [
        (CGRect(x: 0, y: 0, width: 20, height: 20), UIColor.red),
        (CGRect(x: 100, y: 60, width: 20, height: 20), .blue),
      ] {
        let corner = UIView(frame: frame)
        corner.backgroundColor = color
        view.addSubview(corner)
      }
      return view
    }

    /// The reference `pixelFormat` records for `image`.
    private func recordedReference(
      of image: UIImage, in pixelFormat: SnapshotTestingConfiguration.ImagePixelFormat?
    ) throws -> UIImage {
      let diffing = Diffing<UIImage>.image(scale: 1)
      return try withSnapshotTesting(imagePixelFormat: pixelFormat) {
        try diffing.fromData(diffing.toData(image))
      }
    }

    private func differenceImage(_ reference: UIImage, _ candidate: UIImage) throws -> CGImage {
      let (_, attachments) = try XCTUnwrap(
        Diffing<UIImage>.image(scale: 1).diffV2(reference, candidate))
      return try XCTUnwrap(
        attachments.lazy.compactMap { attachment -> UIImage? in
          guard case .data(let data, let name) = attachment, name == "difference.png" else {
            return nil
          }
          return UIImage(data: data)
        }.first?.cgImage)
    }

    private func capture(_ view: UIView) throws -> UIImage {
      var image: UIImage?
      Snapshotting<UIView, UIImage>.image.snapshot(view).run { image = $0 }
      return try XCTUnwrap(image)
    }

    private func temporaryDirectory() throws -> String {
      let directory = NSTemporaryDirectory() + "ImagePixelFormatTests-" + UUID().uuidString
      addTeardownBlock { try? FileManager.default.removeItem(atPath: directory) }
      return directory
    }

    private func referenceData(in directory: String) throws -> Data {
      let name = try XCTUnwrap(
        FileManager.default.contentsOfDirectory(atPath: directory).first { $0.hasSuffix(".png") })
      return try Data(contentsOf: URL(fileURLWithPath: directory + "/" + name))
    }

    private func comparisonBytes(of image: UIImage, format: ImageComparisonFormat) throws -> [UInt8]
    {
      let cgImage = try XCTUnwrap(image.cgImage)
      var bytes = [UInt8](
        repeating: 0, count: cgImage.width * cgImage.height * format.bytesPerPixel)
      let drew = bytes.withUnsafeMutableBytes {
        context(for: cgImage, format: format, data: $0.baseAddress) != nil
      }
      XCTAssertTrue(drew)
      return bytes
    }

    /// A pixel's 8-bit Display P3 components.
    private func pixel(
      of cgImage: CGImage, x: Int, y: Int
    ) throws -> (red: UInt8, green: UInt8, blue: UInt8) {
      let format = ImageComparisonFormat(.displayP3)
      let bytes = try comparisonBytes(of: UIImage(cgImage: cgImage), format: format)
      let offset = (y * cgImage.width + x) * format.bytesPerPixel
      // RGBA bytes; alpha isn't needed.
      return (bytes[offset], bytes[offset + 1], bytes[offset + 2])
    }
  }
#endif
