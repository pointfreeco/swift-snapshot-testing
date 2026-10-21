#if os(iOS) || os(tvOS) || os(macOS)
  import CoreGraphics
  import Foundation

  /// The layout references and snapshots are drawn into to compare them.
  struct ImageComparisonFormat {
    let colorSpace: CGColorSpace?
    let bitsPerComponent: Int
    /// Whether snapshots are converted to this format before they are recorded or compared.
    let convertsSnapshots: Bool
    /// Whether perceptual comparisons color match, rather than reading components as sRGB.
    let colorManaged: Bool

    init(_ pixelFormat: SnapshotTestingConfiguration.ImagePixelFormat?) {
      switch pixelFormat?.storage {
      case .displayP3(let bitDepth):
        self.init(
          colorSpace: CGColorSpace(name: CGColorSpace.displayP3),
          bitsPerComponent: bitDepth.bitsPerComponent,
          convertsSnapshots: true,
          // Unmanaged ΔE would read Display P3 components as linear sRGB.
          colorManaged: true
        )
      case .sRGB(let bitDepth):
        self.init(
          colorSpace: CGColorSpace(name: CGColorSpace.sRGB),
          bitsPerComponent: bitDepth.bitsPerComponent,
          convertsSnapshots: true,
          // Both sides are drawn in sRGB, so unmanaged ΔE compares like with like and keeps the
          // historical values, though it reads encoded components as linear.
          colorManaged: false
        )
      case .automatic, nil:
        // Compared in sRGB too on iOS and tvOS, so unmanaged for the same reason. macOS compares
        // automatic snapshots in the reference's own format instead.
        self.init(
          colorSpace: CGColorSpace(name: CGColorSpace.sRGB), bitsPerComponent: 8,
          convertsSnapshots: false, colorManaged: false)
      }
    }

    private init(
      colorSpace: CGColorSpace?, bitsPerComponent: Int, convertsSnapshots: Bool, colorManaged: Bool
    ) {
      self.colorSpace = colorSpace
      self.bitsPerComponent = bitsPerComponent
      self.convertsSnapshots = convertsSnapshots
      self.colorManaged = colorManaged
    }

    var bytesPerComponent: Int { bitsPerComponent / 8 }
    var bytesPerPixel: Int { 4 * bytesPerComponent }
    // 16-bit components are little-endian, the order normalizedComponentDiff reads them in.
    var bitmapInfo: UInt32 {
      bitsPerComponent == 16
        ? CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder16Little.rawValue
        : CGImageAlphaInfo.premultipliedLast.rawValue
    }

    func withBitsPerComponent(_ bitsPerComponent: Int) -> Self {
      Self(
        colorSpace: colorSpace, bitsPerComponent: bitsPerComponent,
        convertsSnapshots: convertsSnapshots, colorManaged: colorManaged)
    }

    /// Whether `cgImage` already has this colorspace and depth, so converting it wouldn't change
    /// its colors. Alpha layout and byte order may differ, as comparisons redraw into this layout.
    func isRepresentation(of cgImage: CGImage) -> Bool {
      cgImage.bitsPerComponent == bitsPerComponent
        && !cgImage.bitmapInfo.contains(.floatComponents)
        && cgImage.colorSpace?.name == colorSpace?.name
    }
  }

  /// `cgImage` converted to `format`, keeping its pixel dimensions, or nil when the format doesn't
  /// convert snapshots, the image is already in it, or a context can't be allocated.
  func convertedImage(_ cgImage: CGImage, to format: ImageComparisonFormat) -> CGImage? {
    guard format.convertsSnapshots, !format.isRepresentation(of: cgImage) else { return nil }
    return context(for: cgImage, format: format)?.makeImage()
  }

  /// `cgImage` in `format`'s layout without an alpha channel, or nil when the format doesn't
  /// convert snapshots or a pixel isn't fully opaque.
  func opaqueImage(_ cgImage: CGImage, format: ImageComparisonFormat) -> CGImage? {
    guard format.convertsSnapshots, let bytes = bitmap(of: cgImage, format: format) else {
      return nil
    }
    // Alpha is the last component of each pixel; 16-bit components are two bytes.
    var index = format.bytesPerPixel - format.bytesPerComponent
    while index < bytes.count {
      defer { index += format.bytesPerPixel }
      if bytes[index] != .max || (format.bytesPerComponent == 2 && bytes[index + 1] != .max) {
        return nil
      }
    }
    guard
      let colorSpace = format.colorSpace,
      let provider = CGDataProvider(data: Data(bytes) as CFData)
    else { return nil }
    return CGImage(
      width: cgImage.width,
      height: cgImage.height,
      bitsPerComponent: format.bitsPerComponent,
      bitsPerPixel: format.bytesPerPixel * 8,
      bytesPerRow: cgImage.width * format.bytesPerPixel,
      space: colorSpace,
      // Fully opaque premultiplied components equal the unpremultiplied ones, so the bytes are
      // reused as is.
      bitmapInfo: CGBitmapInfo(
        rawValue: format.bitmapInfo & ~CGBitmapInfo.alphaInfoMask.rawValue
          | CGImageAlphaInfo.noneSkipLast.rawValue),
      provider: provider,
      decode: nil,
      shouldInterpolate: false,
      intent: .defaultIntent
    )
  }

  /// `cgImage` drawn into `format`'s layout.
  func bitmap(of cgImage: CGImage, format: ImageComparisonFormat) -> [UInt8]? {
    var bytes = [UInt8](repeating: 0, count: cgImage.width * cgImage.height * format.bytesPerPixel)
    let drew = bytes.withUnsafeMutableBytes {
      context(for: cgImage, format: format, data: $0.baseAddress) != nil
    }
    return drew ? bytes : nil
  }

  func context(
    for cgImage: CGImage, format: ImageComparisonFormat, data: UnsafeMutableRawPointer? = nil
  ) -> CGContext? {
    // Unpadded rows: bitmap(of:) sizes its buffer for exactly this, and equal-size bitmaps compare
    // byte for byte.
    let bytesPerRow = cgImage.width * format.bytesPerPixel
    guard
      let colorSpace = format.colorSpace,
      let context = CGContext(
        data: data,
        width: cgImage.width,
        height: cgImage.height,
        bitsPerComponent: format.bitsPerComponent,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: format.bitmapInfo
      )
    else { return nil }

    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
    return context
  }
#endif
