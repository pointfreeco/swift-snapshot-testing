#if os(iOS) || os(tvOS)
  import SnapshotTesting
  import UIKit
  import XCTest

  final class DifferenceImageLayoutTests: XCTestCase {
    private struct Pixel: Hashable, CustomStringConvertible {
      let x: Int
      let y: Int
      var description: String { "(\(x), \(y))" }
    }

    private struct Layout {
      let name: String
      let colorSpace: CFString
      let components: Int
      let hasAlpha: Bool
      var bitsPerComponent = 8
      var rowPadding = 0
    }

    // Odd and non-square, so rows aren't aligned and swapped axes show.
    private let width = 37
    private let height = 23
    private let changed = Pixel(x: 11, y: 5)

    private let rgba = Layout(
      name: "RGBA", colorSpace: CGColorSpace.sRGB, components: 4, hasAlpha: true)
    private let layouts = [
      Layout(
        name: "padded RGB", colorSpace: CGColorSpace.sRGB, components: 3, hasAlpha: false,
        // 5 bytes isn't a whole pixel, so a reader that assumes packed rows drifts.
        rowPadding: 5),
      Layout(
        name: "gray", colorSpace: CGColorSpace.genericGrayGamma2_2, components: 1, hasAlpha: false),
      // [#1109](https://github.com/pointfreeco/swift-snapshot-testing/pull/1109): the reported
      // gray+alpha snapshot had rows padded to a multiple of 64 bytes; 37 two-byte pixels plus 54
      // bytes is 128.
      Layout(
        name: "padded gray+alpha", colorSpace: CGColorSpace.genericGrayGamma2_2, components: 2,
        hasAlpha: true, rowPadding: 54),
      Layout(
        name: "16-bit RGBA", colorSpace: CGColorSpace.sRGB, components: 4, hasAlpha: true,
        bitsPerComponent: 16),
      Layout(
        name: "16-bit Display P3", colorSpace: CGColorSpace.displayP3, components: 4,
        hasAlpha: true, bitsPerComponent: 16),
    ]

    // [#1097](https://github.com/pointfreeco/swift-snapshot-testing/issues/1097),
    // [#1111](https://github.com/pointfreeco/swift-snapshot-testing/issues/1111): difference images
    // read raw bitmaps as packed 8-bit RGBA, lighting the wrong pixels or reading past the end of
    // the bitmap.
    func testDifferenceImageLightsOnlyChangedPixelInEveryLayout() throws {
      // Pairing with 8-bit RGBA also mixes 16-bit and 8-bit images.
      let pairs = [(rgba, rgba)] + layouts.flatMap { [($0, $0), ($0, rgba), (rgba, $0)] }
      for (changedLayout, plainLayout) in pairs {
        let changedImage = try bitmap(changedLayout, changed: true)
        let plainImage = try bitmap(plainLayout, changed: false)
        for (reference, snapshot, label) in [
          (changedImage, plainImage, "changed \(changedLayout.name) vs \(plainLayout.name)"),
          (plainImage, changedImage, "\(plainLayout.name) vs changed \(changedLayout.name)"),
        ] {
          XCTAssertEqual(try litPixels(reference, snapshot, label), [changed], label)
        }
      }
    }

    // [#1111](https://github.com/pointfreeco/swift-snapshot-testing/issues/1111): renderers draw
    // achromatic views into gray+alpha bitmaps, which record as grayscale PNGs.
    func testDifferenceImageOfRenderedViewLightsOnlyChangedPixel() throws {
      let diffing = Diffing<UIImage>.image(scale: 1)
      // [#1109](https://github.com/pointfreeco/swift-snapshot-testing/pull/1109): the crash paired
      // an RGB image with a gray+alpha one; the pink marker colors only the marked render. Both
      // markers differ from white by half intensity, as in `bitmap(_:changed:)`.
      let markers = [
        ("gray", UIColor(white: 0.5, alpha: 1)),
        ("pink", UIColor(red: 1, green: 0.5, blue: 1, alpha: 1)),
      ]
      for (name, marker) in markers {
        for (recorded, live) in [(nil, marker), (marker, nil)] as [(UIColor?, UIColor?)] {
          let reference = try diffing.fromData(diffing.toData(viewSnapshot(marker: recorded)))
          let snapshot = try viewSnapshot(marker: live)
          let label = """
            \(name) marker in \(recorded == nil ? "snapshot" : "reference"), \
            \(reference.cgImage?.bitsPerPixel ?? 0) bpp vs \(snapshot.cgImage?.bitsPerPixel ?? 0) bpp
            """
          XCTAssertEqual(try litPixels(reference, snapshot, label), [changed], label)
        }
      }
    }

    /// An opaque black bitmap whose changed pixel, if `changed`, is at half intensity.
    ///
    /// Half intensity distinguishes the component difference, which stretches it to full
    /// intensity, from the blend-mode fallback, which leaves it below half.
    private func bitmap(_ layout: Layout, changed isChanged: Bool) throws -> UIImage {
      let bytesPerComponent = layout.bitsPerComponent / 8
      let alpha = [UInt8](repeating: .max, count: layout.hasAlpha ? bytesPerComponent : 0)
      let colorByteCount = layout.components * bytesPerComponent - alpha.count
      var bytes: [UInt8] = []
      for y in 0..<height {
        for x in 0..<width {
          // 0x80 is half intensity.
          let value: UInt8 = isChanged && Pixel(x: x, y: y) == changed ? 0x80 : 0
          bytes += [UInt8](repeating: value, count: colorByteCount) + alpha
        }
        // Nonzero, so padding read as pixels shows up in the difference image.
        bytes += [UInt8](repeating: 0x7F, count: layout.rowPadding)
      }
      var bitmapInfo =
        layout.hasAlpha
        ? CGImageAlphaInfo.premultipliedLast.rawValue : CGImageAlphaInfo.none.rawValue
      if layout.bitsPerComponent == 16 { bitmapInfo |= CGBitmapInfo.byteOrder16Little.rawValue }
      let image = try XCTUnwrap(
        CGImage(
          width: width, height: height, bitsPerComponent: layout.bitsPerComponent,
          bitsPerPixel: layout.components * layout.bitsPerComponent,
          bytesPerRow: bytes.count / height,
          space: XCTUnwrap(CGColorSpace(name: layout.colorSpace)),
          bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
          provider: XCTUnwrap(CGDataProvider(data: Data(bytes) as CFData)), decode: nil,
          shouldInterpolate: false, intent: .defaultIntent))
      return UIImage(cgImage: image, scale: 1, orientation: .up)
    }

    /// A white view with, optionally, a marker on the changed pixel.
    private func viewSnapshot(marker: UIColor?) throws -> UIImage {
      let view = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
      view.backgroundColor = .white
      if let marker {
        let markerView = UIView(frame: CGRect(x: changed.x, y: changed.y, width: 1, height: 1))
        markerView.backgroundColor = marker
        view.addSubview(markerView)
      }
      var image: UIImage?
      Snapshotting<UIView, UIImage>.image(traits: UITraitCollection(displayScale: 1))
        .snapshot(view).run { image = $0 }
      return try XCTUnwrap(image)
    }

    /// The pixels at half intensity or more in the difference image of a failed comparison.
    private func litPixels(_ reference: UIImage, _ snapshot: UIImage, _ label: String) throws
      -> [Pixel]
    {
      let (message, attachments) = try XCTUnwrap(
        Diffing<UIImage>.image(scale: 1).diffV2(reference, snapshot), label)
      XCTAssertEqual(message, "Newly-taken snapshot does not match reference.", label)
      let data = try XCTUnwrap(
        attachments.lazy.compactMap { attachment -> Data? in
          guard case .data(let data, let name) = attachment, name == "difference.png" else {
            return nil
          }
          return data
        }.first, label)
      let difference = try XCTUnwrap(UIImage(data: data)?.cgImage, label)
      XCTAssertEqual([difference.width, difference.height], [width, height], label)
      var bytes = [UInt8](repeating: 0, count: width * height)
      let space = try XCTUnwrap(CGColorSpace(name: CGColorSpace.linearGray))
      let drew = bytes.withUnsafeMutableBytes { buffer -> Bool in
        guard
          let context = CGContext(
            data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width, space: space, bitmapInfo: CGImageAlphaInfo.none.rawValue)
        else { return false }
        context.draw(difference, in: CGRect(x: 0, y: 0, width: width, height: height))
        return true
      }
      XCTAssertTrue(drew, label)
      // One byte per pixel in rows of `width`; 128 is half intensity.
      return bytes.indices.filter { bytes[$0] >= 128 }.map { Pixel(x: $0 % width, y: $0 / width) }
    }
  }
#endif
