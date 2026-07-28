#if os(macOS)
  import Cocoa
  import XCTest

  extension Diffing where Value == NSImage {
    /// A pixel-diffing strategy for NSImage's which requires a 100% match.
    public static let image = Diffing.image()

    /// A pixel-diffing strategy for NSImage that allows customizing how precise the matching must be.
    ///
    /// - Parameters:
    ///   - precision: The percentage of pixels that must match.
    ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
    ///     match. 98-99% mimics
    ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
    ///     human eye.
    /// - Returns: A new diffing strategy.
    public static func image(precision: Float = 1, perceptualPrecision: Float = 1) -> Diffing {
      // The pixel format is resolved when recording and comparing, which run inside the assertion's
      // configuration scope; snapshots can arrive in callbacks outside it.
      return .diff(
        toData: { image in
          let format = ImageComparisonFormat(_imagePixelFormat)
          guard
            let data = NSImagePNGRepresentation(
              withoutAlphaIfOpaque(normalized(image, to: format), format: format))
          else {
            throw ImageEncodingError(image)
          }
          return data
        },
        fromData: { data in
          try ImageReferenceError.validate(data)
          guard let image = NSImage(data: data), image.isValid else {
            throw ImageReferenceError(data: data)
          }
          return image
        }
      ) { old, new in
        let format = ImageComparisonFormat(_imagePixelFormat)
        let new = normalized(new, to: format)
        guard
          let message = compare(
            old, new, precision: precision, perceptualPrecision: perceptualPrecision,
            format: format)
        else { return nil }
        let difference = SnapshotTesting.diff(old, new)
        // An attachment that can't be encoded is left out; the message still reports the failure.
        let attachments = [
          ("reference.png", old), ("failure.png", new), ("difference.png", difference),
        ]
        .compactMap { name, image in
          image.flatMap(NSImagePNGRepresentation).map { DiffAttachment.data($0, name: name) }
        }
        return (message, attachments)
      }
    }
  }

  extension Snapshotting where Value == NSImage, Format == NSImage {
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
    public static func image(precision: Float = 1, perceptualPrecision: Float = 1) -> Snapshotting {
      return .init(
        pathExtension: "png",
        diffing: .image(precision: precision, perceptualPrecision: perceptualPrecision)
      )
    }
  }

  /// Converts a snapshot to `format` when the format requires it, keeping its pixel dimensions and
  /// point size. The snapshot is returned unchanged when it can't be converted, and comparing it
  /// fails the same way.
  func normalized(_ image: NSImage, to format: ImageComparisonFormat) -> NSImage {
    guard
      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
      let converted = convertedImage(cgImage, to: format)
    else { return image }
    return NSImage(cgImage: converted, size: image.size)
  }

  /// Drops the alpha channel of a converted snapshot whose pixels are all opaque, so its reference
  /// encodes as a smaller RGB PNG. The comparison context restores full opacity when drawing it, so
  /// comparisons are unaffected.
  func withoutAlphaIfOpaque(_ image: NSImage, format: ImageComparisonFormat) -> NSImage {
    guard
      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
      let opaque = opaqueImage(cgImage, format: format)
    else { return image }
    return NSImage(cgImage: opaque, size: image.size)
  }

  private func NSImagePNGRepresentation(_ image: NSImage) -> Data? {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return nil
    }
    let rep = NSBitmapImageRep(cgImage: cgImage)
    rep.size = image.size
    return rep.representation(using: .png, properties: [:])
  }

  private func compare(
    _ old: NSImage, _ new: NSImage, precision: Float, perceptualPrecision: Float,
    format: ImageComparisonFormat
  ) -> String? {
    guard let oldCgImage = old.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return "Reference image could not be loaded."
    }
    guard let newCgImage = new.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return "Newly-taken snapshot could not be loaded."
    }
    guard newCgImage.width != 0, newCgImage.height != 0 else {
      return "Newly-taken snapshot is empty."
    }
    guard oldCgImage.width == newCgImage.width, oldCgImage.height == newCgImage.height else {
      return "Newly-taken snapshot@\(new.size) does not match reference@\(old.size)."
    }
    // Every image is drawn into the format, or without one like the reference: the snapshot's own
    // colorspace, bit depth and row length can differ from it, so its own bytes wouldn't be
    // comparable.
    func draw(_ cgImage: CGImage) -> CGContext? {
      format.convertsSnapshots
        ? context(for: cgImage, format: format) : context(for: cgImage, like: oldCgImage)
    }
    guard let oldContext = draw(oldCgImage), let oldData = oldContext.data else {
      return "Reference image's data could not be loaded."
    }
    guard let newContext = draw(newCgImage), let newData = newContext.data else {
      return "Newly-taken snapshot's data could not be loaded."
    }
    let byteCount = oldContext.height * oldContext.bytesPerRow
    if memcmp(oldData, newData, byteCount) == 0 { return nil }
    // The snapshot as it would be recorded: PNG encoding can change pixels.
    guard
      let pngData = NSImagePNGRepresentation(new),
      let newerCgImage = NSImage(data: pngData)?.cgImage(
        forProposedRect: nil, context: nil, hints: nil),
      let newerContext = draw(newerCgImage),
      let newerData = newerContext.data
    else {
      return "Newly-taken snapshot's data could not be loaded."
    }
    if memcmp(oldData, newerData, byteCount) == 0 { return nil }
    if precision >= 1, perceptualPrecision >= 1 {
      return "Newly-taken snapshot does not match reference."
    }
    if perceptualPrecision < 1, format.convertsSnapshots, #available(macOS 10.13, *) {
      // Drawing at 16 bits keeps differences smaller than one 8-bit step from becoming whole steps,
      // which near black are worth several ΔE.
      let perceptualFormat = format.withBitsPerComponent(16)
      guard
        let oldImage = context(for: oldCgImage, format: perceptualFormat)?.makeImage(),
        let newerImage = context(for: newerCgImage, format: perceptualFormat)?.makeImage()
      else {
        return "Newly-taken snapshot's data could not be processed."
      }
      return perceptuallyCompare(
        CIImage(cgImage: oldImage),
        CIImage(cgImage: newerImage),
        pixelPrecision: precision,
        perceptualPrecision: perceptualPrecision,
        colorManaged: format.colorManaged
      )
    } else if perceptualPrecision < 1, #available(macOS 10.13, *) {
      // Images in different colorspaces are measured as drawn, as the byte comparisons saw them,
      // and color matched. Same-colorspace comparisons keep the unmanaged measure's values. The
      // snapshot is measured as encoded, like the reference: encoding can rename a colorspace, such
      // as DeviceRGB or a screen's, without changing its colors.
      let sharesColorSpace = oldCgImage.colorSpace == newerCgImage.colorSpace
      guard
        let oldImage = sharesColorSpace ? oldCgImage : oldContext.makeImage(),
        let newerImage = sharesColorSpace ? newerCgImage : newerContext.makeImage()
      else {
        return "Newly-taken snapshot's data could not be processed."
      }
      return perceptuallyCompare(
        CIImage(cgImage: oldImage),
        CIImage(cgImage: newerImage),
        pixelPrecision: precision,
        perceptualPrecision: perceptualPrecision,
        colorManaged: !sharesColorSpace
      )
    } else {
      let oldRep = NSBitmapImageRep(cgImage: oldCgImage)
      let newerRep = NSBitmapImageRep(cgImage: newerCgImage)
      // Without a format, images in the same format count their own bytes, which precision
      // thresholds were tuned against. Others count the drawn bytes: raw bitmaps in different
      // formats aren't comparable, and a shorter one would be over-read.
      let bitmaps =
        !format.convertsSnapshots && sharesFormat(oldCgImage, newerCgImage)
          && oldRep.bytesPerPlane >= byteCount && newerRep.bytesPerPlane >= byteCount
        ? oldRep.bitmapData.flatMap { old in newerRep.bitmapData.map { (old, $0) } } : nil
      let oldBytes = bitmaps?.0 ?? oldData.assumingMemoryBound(to: UInt8.self)
      let newerBytes = bitmaps?.1 ?? newerData.assumingMemoryBound(to: UInt8.self)
      // A format's precision counts color components: one byte each in 8-bit formats, two in
      // 16-bit ones.
      let bytesPerComponent = format.convertsSnapshots ? format.bytesPerComponent : 1
      let componentCount = byteCount / bytesPerComponent
      let componentCountThreshold = Int((1 - precision) * Float(componentCount))
      var differentComponentCount = 0
      // NB: We are purposely using a verbose 'while' loop instead of a 'for in' loop.  When the
      //     compiler doesn't have optimizations enabled, like in test targets, a `while` loop is
      //     significantly faster than a `for` loop for iterating through the elements of a memory
      //     buffer. Details can be found in [SR-6983](https://github.com/apple/swift/issues/49531)
      var index = 0
      // The bytes point into these objects' memory, which ARC could otherwise free after their last
      // use, before the loop reads it.
      withExtendedLifetime((oldRep, newerRep, oldContext, newerContext)) {
        while index < byteCount {
          defer { index += bytesPerComponent }
          if oldBytes[index] != newerBytes[index]
            || (bytesPerComponent == 2 && oldBytes[index + 1] != newerBytes[index + 1])
          {
            differentComponentCount += 1
          }
        }
      }
      if differentComponentCount > componentCountThreshold {
        let actualPrecision = 1 - Float(differentComponentCount) / Float(componentCount)
        return "Actual image precision \(actualPrecision) is less than required \(precision)"
      }
    }
    return nil
  }

  private func sharesFormat(_ lhs: CGImage, _ rhs: CGImage) -> Bool {
    lhs.colorSpace == rhs.colorSpace && lhs.bitsPerComponent == rhs.bitsPerComponent
      && lhs.bitsPerPixel == rhs.bitsPerPixel && lhs.bytesPerRow == rhs.bytesPerRow
      && lhs.bitmapInfo == rhs.bitmapInfo
  }

  // Core Graphics can't draw premultiplied RGBA into gray, float or unpadded RGB layouts.
  private func context(for cgImage: CGImage, like reference: CGImage) -> CGContext? {
    func makeContext(space: CGColorSpace?, bitsPerComponent: Int, bytesPerRow: Int) -> CGContext? {
      space.flatMap {
        CGContext(
          data: nil,
          width: cgImage.width,
          height: cgImage.height,
          bitsPerComponent: bitsPerComponent,
          bytesPerRow: bytesPerRow,
          space: $0,
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
      }
    }
    // The fallback is unpadded RGBA in the reference's RGB colorspace, or sRGB, at 16 bits for
    // references deeper than 8, so it keeps their colors and precision.
    let bitsPerComponent = reference.bitsPerComponent > 8 ? 16 : 8
    let rgbSpace = reference.colorSpace.flatMap { $0.model == .rgb && $0.supportsOutput ? $0 : nil }
    guard
      let context = makeContext(
        space: reference.colorSpace,
        bitsPerComponent: reference.bitsPerComponent,
        bytesPerRow: reference.bytesPerRow
      )
        ?? makeContext(
          space: rgbSpace ?? CGColorSpace(name: CGColorSpace.sRGB),
          bitsPerComponent: bitsPerComponent,
          bytesPerRow: cgImage.width * 4 * bitsPerComponent / 8
        )
    else { return nil }

    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
    return context
  }

  private func diff(_ old: NSImage, _ new: NSImage) -> NSImage? {
    guard
      let oldCgImage = old.cgImage(forProposedRect: nil, context: nil, hints: nil),
      let newCgImage = new.cgImage(forProposedRect: nil, context: nil, hints: nil),
      let differenceFilter = CIFilter(name: "CIDifferenceBlendMode")
    else { return nil }
    differenceFilter.setValue(CIImage(cgImage: oldCgImage), forKey: kCIInputImageKey)
    differenceFilter.setValue(CIImage(cgImage: newCgImage), forKey: kCIInputBackgroundImageKey)
    let maxSize = CGSize(
      width: max(old.size.width, new.size.width),
      height: max(old.size.height, new.size.height)
    )
    guard let outputImage = differenceFilter.outputImage else { return nil }
    let rep = NSCIImageRep(ciImage: outputImage)
    let difference = NSImage(size: maxSize)
    difference.addRepresentation(rep)
    return difference
  }
#endif
