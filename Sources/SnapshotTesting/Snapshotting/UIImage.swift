#if os(iOS) || os(tvOS)
  import UIKit

  extension Diffing where Value == UIImage {
    /// A pixel-diffing strategy for UIImage's which requires a 100% match.
    public static let image = Diffing.image()

    /// A pixel-diffing strategy for UIImage that allows customizing how precise the matching must be.
    ///
    /// - Parameters:
    ///   - precision: The percentage of pixels that must match.
    ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
    ///     match. 98-99% mimics
    ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
    ///     human eye.
    ///   - scale: Scale to use when loading the reference image from disk. If `nil` or the
    ///     `UITraitCollection`s default value of `0.0`, the screens scale is used.
    /// - Returns: A new diffing strategy.
    public static func image(
      precision: Float = 1, perceptualPrecision: Float = 1, scale: CGFloat? = nil
    ) -> Diffing {
      let imageScale: CGFloat
      if let scale = scale, scale != 0.0 {
        imageScale = scale
      } else {
        imageScale = UIScreen.main.scale
      }
      let toData: (UIImage) throws -> Data = { image in
        if let data = image.pngData() { return data }
        let error = ImageEncodingError(image)
        // A snapshot without image data, such as one of a zero-size view, records a placeholder
        // that explains how to fix it.
        if case .noImageData = error.reason, let data = emptyImage().pngData() { return data }
        throw error
      }
      let decode: (Data) throws -> UIImage = { data in
        try ImageReferenceError.validate(data)
        guard let image = UIImage(data: data, scale: imageScale) else {
          throw ImageReferenceError(data: data)
        }
        return image
      }
      // The pixel format is resolved when recording and comparing, which run inside the assertion's
      // configuration scope; snapshots can arrive in callbacks outside it.
      return .diff(
        toData: { snapshot in
          let format = ImageComparisonFormat(_imagePixelFormat)
          return try toData(withoutAlphaIfOpaque(normalized(snapshot, to: format), format: format))
        },
        fromData: decode
      ) { old, new in
        let format = ImageComparisonFormat(_imagePixelFormat)
        let new = normalized(new, to: format)
        guard
          let failure = compare(
            old, new, precision: precision, perceptualPrecision: perceptualPrecision,
            format: format)
        else { return nil }
        let message = failure.message
        let difference =
          failure.bitmaps.flatMap { normalizedComponentDiff($0, format: format, scale: old.scale) }
          ?? blendModeDiff(old, new)
        let isEmptyImage = new.size == .zero
        // An attachment that can't be encoded is left out; the message still reports the failure.
        let attachments = [
          ("reference.png", old), ("failure.png", isEmptyImage ? emptyImage() : new),
          ("difference.png", difference),
        ].compactMap { name, image in
          (try? toData(image)).map { DiffAttachment.data($0, name: name) }
        }
        return (message, attachments)
      }
    }

    /// Used when the image size has no width or no height to generated the default empty image
    private static func emptyImage() -> UIImage {
      let label = UILabel(frame: CGRect(x: 0, y: 0, width: 400, height: 80))
      label.backgroundColor = .red
      label.text =
        "Error: No image could be generated for this view as its size was zero. Please set an explicit size in the test."
      label.textAlignment = .center
      label.numberOfLines = 3
      return label.asImage()
    }
  }

  extension Snapshotting where Value == UIImage, Format == UIImage {
    /// A snapshot strategy for comparing images based on pixel equality.
    public static var image: Snapshotting {
      return .image()
    }

    /// A snapshot strategy for comparing images based on pixel equality.
    ///
    /// - Parameters:
    ///   - precision: The percentage of pixels that must match.
    ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
    ///     match. 98-99% mimics
    ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
    ///     human eye.
    ///   - scale: The scale of the reference image stored on disk.
    public static func image(
      precision: Float = 1, perceptualPrecision: Float = 1, scale: CGFloat? = nil
    ) -> Snapshotting {
      return .init(
        pathExtension: "png",
        diffing: .image(
          precision: precision, perceptualPrecision: perceptualPrecision, scale: scale)
      )
    }
  }

  /// Converts a snapshot to `format` when the format requires it, keeping its pixel dimensions,
  /// scale and orientation. Symbol images are drawn first, as UIKit draws them, so their tint and
  /// padding are kept and their orientation is applied to the pixels.
  ///
  /// Recording depends on this: UIKit clips colors outside sRGB when it encodes extended-range
  /// images as PNG. Conversion fails only for images without bitmap data or when a context can't be
  /// allocated; the snapshot is then returned unconverted, and comparing it fails the same way.
  func normalized(_ image: UIImage, to format: ImageComparisonFormat) -> UIImage {
    guard format.convertsSnapshots else { return image }
    // A symbol image's cgImage is its untinted template cropped to the glyph, not what UIKit draws.
    let image = image.isSymbolImage ? drawn(image) : image
    guard let cgImage = image.cgImage, let converted = convertedImage(cgImage, to: format) else {
      return image
    }
    return UIImage(cgImage: converted, scale: image.scale, orientation: image.imageOrientation)
  }

  private func drawn(_ image: UIImage) -> UIImage {
    let format = UIGraphicsImageRendererFormat.preferred()
    format.scale = image.scale
    return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
      image.draw(at: .zero)
    }
  }

  /// Drops the alpha channel of a converted snapshot whose pixels are all opaque, so its reference
  /// encodes as a smaller RGB PNG. The comparison context restores full opacity when drawing it, so
  /// comparisons are unaffected.
  func withoutAlphaIfOpaque(_ image: UIImage, format: ImageComparisonFormat) -> UIImage {
    guard let cgImage = image.cgImage, let opaque = opaqueImage(cgImage, format: format) else {
      return image
    }
    return UIImage(cgImage: opaque, scale: image.scale, orientation: image.imageOrientation)
  }

  /// The reference and the snapshot as they were compared, in the comparison layout.
  private struct ComparisonBitmaps {
    let old: [UInt8]
    let new: [UInt8]
    let width: Int
    let height: Int
  }

  private struct ComparisonFailure {
    let message: String
    /// The compared pixels, when the comparison got as far as reading them.
    var bitmaps: ComparisonBitmaps?
  }

  private func compare(
    _ old: UIImage, _ new: UIImage, precision: Float, perceptualPrecision: Float,
    format: ImageComparisonFormat
  ) -> ComparisonFailure? {
    guard let oldCgImage = old.cgImage else {
      return ComparisonFailure(message: "Reference image could not be loaded.")
    }
    guard let newCgImage = new.cgImage else {
      return ComparisonFailure(message: "Newly-taken snapshot could not be loaded.")
    }
    guard newCgImage.width != 0, newCgImage.height != 0 else {
      return ComparisonFailure(message: "Newly-taken snapshot is empty.")
    }
    guard oldCgImage.width == newCgImage.width, oldCgImage.height == newCgImage.height else {
      return ComparisonFailure(
        message: "Newly-taken snapshot@\(new.size) does not match reference@\(old.size).")
    }
    guard let oldBytes = bitmap(of: oldCgImage, format: format) else {
      return ComparisonFailure(message: "Reference image's data could not be loaded.")
    }
    // Most matches are equal before the PNG round trip below, which is then skipped.
    if let newBytes = bitmap(of: newCgImage, format: format), bytesEqual(oldBytes, newBytes) {
      return nil
    }
    // The snapshot as it would be recorded: PNG encoding can change pixels, for example by clipping
    // extended-range colors.
    guard
      let pngData = new.pngData(),
      let newerCgImage = UIImage(data: pngData)?.cgImage,
      let newerBytes = bitmap(of: newerCgImage, format: format)
    else {
      return ComparisonFailure(message: "Newly-taken snapshot's data could not be loaded.")
    }
    if bytesEqual(oldBytes, newerBytes) { return nil }
    let bitmaps = ComparisonBitmaps(
      old: oldBytes, new: newerBytes, width: oldCgImage.width, height: oldCgImage.height)
    if precision >= 1, perceptualPrecision >= 1 {
      return ComparisonFailure(
        message: "Newly-taken snapshot does not match reference.", bitmaps: bitmaps)
    }
    if perceptualPrecision < 1, #available(iOS 11.0, tvOS 11.0, *) {
      // Compare the pixels the byte comparisons above saw. The original images can be in different
      // colorspaces, and wide-gamut colors that UIKit clipped while encoding the reference would
      // otherwise read as differences. Drawing at 16 bits keeps differences smaller than one 8-bit
      // step from becoming whole steps, which near black are worth several ΔE.
      let perceptualFormat = format.withBitsPerComponent(16)
      guard
        let oldImage = context(for: oldCgImage, format: perceptualFormat)?.makeImage(),
        let newerImage = context(for: newerCgImage, format: perceptualFormat)?.makeImage()
      else {
        return ComparisonFailure(
          message: "Newly-taken snapshot's data could not be processed.", bitmaps: bitmaps)
      }
      return perceptuallyCompare(
        CIImage(cgImage: oldImage),
        CIImage(cgImage: newerImage),
        pixelPrecision: precision,
        perceptualPrecision: perceptualPrecision,
        colorManaged: format.colorManaged
      ).map { ComparisonFailure(message: $0, bitmaps: bitmaps) }
    } else {
      // Precision counts color components: one byte each in 8-bit formats, two in 16-bit ones.
      let bytesPerComponent = format.bytesPerComponent
      let byteCount = oldBytes.count
      let componentCount = byteCount / bytesPerComponent
      let componentCountThreshold = Int((1 - precision) * Float(componentCount))
      var differentComponentCount = 0
      // NB: We are purposely using a verbose 'while' loop instead of a 'for in' loop.  When the
      //     compiler doesn't have optimizations enabled, like in test targets, a `while` loop is
      //     significantly faster than a `for` loop for iterating through the elements of a memory
      //     buffer. Details can be found in [SR-6983](https://github.com/apple/swift/issues/49531)
      var index = 0
      while index < byteCount {
        defer { index += bytesPerComponent }
        if oldBytes[index] != newerBytes[index]
          || (bytesPerComponent == 2 && oldBytes[index + 1] != newerBytes[index + 1])
        {
          differentComponentCount += 1
        }
      }
      if differentComponentCount > componentCountThreshold {
        let actualPrecision = 1 - Float(differentComponentCount) / Float(componentCount)
        return ComparisonFailure(
          message: "Actual image precision \(actualPrecision) is less than required \(precision)",
          bitmaps: bitmaps)
      }
    }
    return nil
  }

  private func bytesEqual(_ lhs: [UInt8], _ rhs: [UInt8]) -> Bool {
    guard lhs.count == rhs.count else { return false }
    return lhs.withUnsafeBytes { lhsBuffer in
      rhs.withUnsafeBytes { rhsBuffer in
        guard let lhsBase = lhsBuffer.baseAddress, let rhsBase = rhsBuffer.baseAddress else {
          return true
        }
        return memcmp(lhsBase, rhsBase, lhsBuffer.count) == 0
      }
    }
  }

  // UIGraphicsBeginImageContextWithOptions is deprecated and raises an exception for a zero size,
  // aborting the test process, so this uses UIGraphicsImageRenderer.
  private func blendModeDiff(_ old: UIImage, _ new: UIImage) -> UIImage {
    let size = CGSize(
      width: max(old.size.width, new.size.width), height: max(old.size.height, new.size.height))
    guard size.width > 0, size.height > 0 else { return UIImage() }
    let format = UIGraphicsImageRendererFormat()
    format.scale = max(old.scale, new.scale)
    // The difference blend draws |new - old|, so unchanged pixels are black whatever their color;
    // opaque makes areas transparent in both images black too. Alpha-only changes can also draw
    // black, but this only runs when no pixels were compared.
    format.opaque = true
    return UIGraphicsImageRenderer(size: size, format: format).image { _ in
      new.draw(at: .zero)
      old.draw(at: .zero, blendMode: .difference, alpha: 1)
    }
  }

  /// A grayscale image of how much each pixel changed, made from the bytes the comparison read:
  /// black where a pixel is unchanged and brighter the more it changed.
  private func normalizedComponentDiff(
    _ bitmaps: ComparisonBitmaps, format: ImageComparisonFormat, scale: CGFloat
  ) -> UIImage? {
    // One 8-bit linear gray byte per pixel: the largest component difference.
    guard let outputColorSpace = CGColorSpace(name: CGColorSpace.linearGray),
      let outputFormat = vImage_CGImageFormat(
        bitsPerComponent: 8,
        bitsPerPixel: 8,
        colorSpace: outputColorSpace,
        bitmapInfo: .init()
      )
    else {
      return nil
    }

    let width = bitmaps.width
    let height = bitmaps.height
    let pixelCount = width * height
    let oldBytes = bitmaps.old
    let newBytes = bitmaps.new
    var diffBytes = [UInt8](repeating: 0, count: pixelCount)

    // Each pixel's brightness is its largest component difference, so a change to any component,
    // alpha included, lights it.
    var index = 0
    while index < pixelCount {
      defer { index += 1 }
      let pixelOffset = index * format.bytesPerPixel
      var maxDiff = 0
      var component = 0
      // Premultiplied red, green, blue and alpha.
      while component < 4 {
        defer { component += 1 }
        let offset = pixelOffset + component * format.bytesPerComponent
        let difference: Int
        if format.bytesPerComponent == 2 {
          // Little-endian 16-bit components (low byte first).
          let old = Int(oldBytes[offset]) | Int(oldBytes[offset + 1]) << 8
          let new = Int(newBytes[offset]) | Int(newBytes[offset + 1]) << 8
          let delta = abs(old - new)
          // `>> 8` scales to 8 bits; a change smaller than one 8-bit step still counts as 1, which
          // the contrast stretch below makes visible.
          difference = delta == 0 ? 0 : max(delta >> 8, 1)
        } else {
          difference = abs(Int(oldBytes[offset]) - Int(newBytes[offset]))
        }
        maxDiff = max(maxDiff, difference)
      }
      // At most 255: 8-bit differences and shifted 16-bit ones both fit in a byte.
      diffBytes[index] = UInt8(maxDiff)
    }

    let outputCgImage: CGImage? = diffBytes.withUnsafeMutableBytes { diffPtr in
      // Wraps the differences without copying them; their rows are unpadded.
      var diffBuffer = vImage_Buffer(
        data: diffPtr.baseAddress,
        height: vImagePixelCount(height),
        width: vImagePixelCount(width),
        rowBytes: width
      )

      do {
        // Allocated by vImage, which may pad its rows, and freed once the image is made.
        var normalizedBuffer = try vImage_Buffer(
          width: width,
          height: height,
          bitsPerPixel: outputFormat.bitsPerPixel
        )
        defer { normalizedBuffer.free() }

        // Stretches the differences across the full range, so small ones are visible.
        let error = vImageContrastStretch_Planar8(
          &diffBuffer,
          &normalizedBuffer,
          vImage_Flags(kvImageNoFlags)
        )

        // Falls back to the unstretched differences if stretching fails.
        let buffer = error == kvImageNoError ? normalizedBuffer : diffBuffer

        // Copies the pixels, so the image outlives both buffers.
        return try buffer.createCGImage(format: outputFormat)
      } catch {
        return nil
      }
    }

    guard let outputCgImage else { return nil }

    // The reference's scale, so the attachment has its point size.
    return UIImage(cgImage: outputCgImage, scale: scale, orientation: .up)
  }
#endif

#if os(iOS) || os(tvOS) || os(macOS)
  import Accelerate.vImage
  import CoreImage.CIKernel
  import MetalPerformanceShaders

  /// - Parameter colorManaged: Whether to measure color differences between the images' actual
  ///   colors, rather than reading their components as sRGB.
  @available(iOS 10.0, tvOS 10.0, macOS 10.13, *)
  func perceptuallyCompare(
    _ old: CIImage, _ new: CIImage, pixelPrecision: Float, perceptualPrecision: Float,
    colorManaged: Bool
  ) -> String? {
    // Calculate the deltaE values. Each pixel is a value between 0-100.
    // 0 means no difference, 100 means completely opposite.
    let deltaOutputImage = old.applyingLabDeltaE(new)
    // An NSNull working colorspace disables color management: CILabDeltaE then reads encoded
    // components as linear sRGB, which keeps the historical values but compares images in different
    // colorspaces as if they held the same colors. Color managed comparisons convert into extended
    // linear sRGB, the space its Lab conversion assumes. The output is measurements, not colors, so
    // it is never color managed.
    let workingColorSpace: Any =
      colorManaged
      ? CGColorSpace(name: CGColorSpace.extendedLinearSRGB) as Any? ?? NSNull() : NSNull()
    let context = CIContext(
      options: [.workingColorSpace: workingColorSpace, .outputColorSpace: NSNull()])
    let deltaThreshold = (1 - perceptualPrecision) * 100
    let actualPixelPrecision: Float
    var maximumDeltaE: Float = 0

    // Metal is supported by all iOS/tvOS devices (2013 models or later) and Macs (2012 models or later).
    // Older devices do not support iOS/tvOS 13 and macOS 10.15 which are the minimum versions of swift-snapshot-testing.
    // However, some virtualized hardware do not have GPUs and therefore do not support Metal.
    // In this case, macOS falls back to a CPU-based OpenGL ES renderer that silently fails when a Metal command is issued.
    // We need to check for Metal device support and fallback to CPU based vImage buffer iteration.
    if ThresholdImageProcessorKernel.isSupported {
      // Fast path - Metal processing
      guard
        let thresholdOutputImage = try? deltaOutputImage.applyingThreshold(deltaThreshold),
        let averagePixel = thresholdOutputImage.applyingAreaAverage().renderSingleValue(in: context)
      else {
        return "Newly-taken snapshot's data could not be processed."
      }
      actualPixelPrecision = 1 - averagePixel
      if actualPixelPrecision < pixelPrecision {
        maximumDeltaE = deltaOutputImage.applyingAreaMaximum().renderSingleValue(in: context) ?? 0
      }
    } else {
      // Slow path - CPU based vImage buffer iteration
      guard let buffer = deltaOutputImage.render(in: context) else {
        return "Newly-taken snapshot could not be processed."
      }
      defer { buffer.free() }
      var failingPixelCount: Int = 0
      // rowBytes must be a multiple of 8, so vImage_Buffer pads the end of each row with bytes to meet the multiple of 0 requirement.
      // We must do 2D iteration of the vImage_Buffer in order to avoid loading the padding garbage bytes at the end of each row.
      //
      // NB: We are purposely using a verbose 'while' loop instead of a 'for in' loop.  When the
      //     compiler doesn't have optimizations enabled, like in test targets, a `while` loop is
      //     significantly faster than a `for` loop for iterating through the elements of a memory
      //     buffer. Details can be found in [SR-6983](https://github.com/apple/swift/issues/49531)
      let componentStride = MemoryLayout<Float>.stride
      var line = 0
      while line < buffer.height {
        defer { line += 1 }
        let lineOffset = buffer.rowBytes * line
        var column = 0
        while column < buffer.width {
          defer { column += 1 }
          let byteOffset = lineOffset + column * componentStride
          let deltaE = buffer.data.load(fromByteOffset: byteOffset, as: Float.self)
          if deltaE > deltaThreshold {
            failingPixelCount += 1
            if deltaE > maximumDeltaE {
              maximumDeltaE = deltaE
            }
          }
        }
      }
      let failingPixelPercent =
        Float(failingPixelCount)
        / Float(deltaOutputImage.extent.width * deltaOutputImage.extent.height)
      actualPixelPrecision = 1 - failingPixelPercent
    }

    guard actualPixelPrecision < pixelPrecision else { return nil }
    // The actual perceptual precision is the perceptual precision of the pixel with the highest DeltaE.
    // DeltaE is in a 0-100 scale, so we need to divide by 100 to transform it to a percentage.
    let minimumPerceptualPrecision = 1 - min(maximumDeltaE / 100, 1)
    return """
      The percentage of pixels that match \(actualPixelPrecision) is less than required \(pixelPrecision)
      The lowest perceptual color precision \(minimumPerceptualPrecision) is less than required \(perceptualPrecision)
      """
  }

  extension CIImage {
    func applyingLabDeltaE(_ other: CIImage) -> CIImage {
      applyingFilter("CILabDeltaE", parameters: ["inputImage2": other])
    }

    func applyingThreshold(_ threshold: Float) throws -> CIImage {
      try ThresholdImageProcessorKernel.apply(
        withExtent: extent,
        inputs: [self],
        arguments: [ThresholdImageProcessorKernel.inputThresholdKey: threshold]
      )
    }

    func applyingAreaAverage() -> CIImage {
      applyingFilter("CIAreaAverage", parameters: [kCIInputExtentKey: CIVector(cgRect: extent)])
    }

    func applyingAreaMaximum() -> CIImage {
      applyingFilter("CIAreaMaximum", parameters: [kCIInputExtentKey: CIVector(cgRect: extent)])
    }

    func renderSingleValue(in context: CIContext) -> Float? {
      guard let buffer = render(in: context) else { return nil }
      defer { buffer.free() }
      return buffer.data.load(fromByteOffset: 0, as: Float.self)
    }

    func render(in context: CIContext, format: CIFormat = CIFormat.Rh) -> vImage_Buffer? {
      // Some hardware configurations (virtualized CPU renderers) do not support 32-bit float output formats,
      // so use a compatible 16-bit float format and convert the output value to 32-bit floats.
      guard
        var buffer16 = try? vImage_Buffer(
          width: Int(extent.width), height: Int(extent.height), bitsPerPixel: 16)
      else { return nil }
      defer { buffer16.free() }
      context.render(
        self,
        toBitmap: buffer16.data,
        rowBytes: buffer16.rowBytes,
        bounds: extent,
        format: format,
        colorSpace: nil
      )
      guard
        var buffer32 = try? vImage_Buffer(
          width: Int(buffer16.width), height: Int(buffer16.height), bitsPerPixel: 32),
        vImageConvert_Planar16FtoPlanarF(&buffer16, &buffer32, 0) == kvImageNoError
      else { return nil }
      return buffer32
    }
  }

  // Copied from https://developer.apple.com/documentation/coreimage/ciimageprocessorkernel
  @available(iOS 10.0, tvOS 10.0, macOS 10.13, *)
  final class ThresholdImageProcessorKernel: CIImageProcessorKernel {
    static let inputThresholdKey = "thresholdValue"
    static let device = MTLCreateSystemDefaultDevice()

    static var isSupported: Bool {
      guard let device = device else {
        return false
      }
      #if targetEnvironment(simulator)
        guard #available(iOS 14.0, tvOS 14.0, *) else {
          // The MPSSupportsMTLDevice method throws an exception on iOS/tvOS simulators < 14.0
          return false
        }
      #endif
      return MPSSupportsMTLDevice(device)
    }

    override class func process(
      with inputs: [CIImageProcessorInput]?, arguments: [String: Any]?,
      output: CIImageProcessorOutput
    ) throws {
      guard
        let device = device,
        let commandBuffer = output.metalCommandBuffer,
        let input = inputs?.first,
        let sourceTexture = input.metalTexture,
        let destinationTexture = output.metalTexture,
        let thresholdValue = arguments?[inputThresholdKey] as? Float
      else {
        return
      }

      let threshold = MPSImageThresholdBinary(
        device: device,
        thresholdValue: thresholdValue,
        maximumValue: 1.0,
        linearGrayColorTransform: nil
      )

      threshold.encode(
        commandBuffer: commandBuffer,
        sourceTexture: sourceTexture,
        destinationTexture: destinationTexture
      )
    }
  }
#endif
