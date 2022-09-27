#if os(iOS) || os(tvOS)
import UIKit
import XCTest

extension Diffing where Value == UIImage {
  /// A pixel-diffing strategy for UIImage's which requires a 100% match.
  public static let image = Diffing.image()

  /// A pixel-diffing strategy for UIImage that allows customizing how precise the matching must be.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match. [98-99% mimics the precision of the human eye.](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e)
  ///   - scale: Scale to use when loading the reference image from disk. If `nil` or the `UITraitCollection`s default value of `0.0`, the screens scale is used.
  /// - Returns: A new diffing strategy.
  public static func image(precision: Float = 1, perceptualPrecision: Float = 1, scale: CGFloat? = nil) -> Diffing {
    let imageScale: CGFloat
    if let scale = scale, scale != 0.0 {
      imageScale = scale
    } else {
      imageScale = UIScreen.main.scale
    }

    return Diffing(
      toData: { $0.pngData() ?? emptyImage().pngData()! },
      fromData: { UIImage(data: $0, scale: imageScale)! }
    ) { old, new in
      guard let message = compare(old, new, precision: precision, perceptualPrecision: perceptualPrecision) else { return nil }
      let difference = SnapshotTesting.diff(old, new)
      let oldAttachment = XCTAttachment(image: old)
      oldAttachment.name = "reference"
      let isEmptyImage = new.size == .zero
      let newAttachment = XCTAttachment(image: isEmptyImage ? emptyImage() : new)
      newAttachment.name = "failure"
      let differenceAttachment = XCTAttachment(image: difference)
      differenceAttachment.name = "difference"
      return (
        message,
        [oldAttachment, newAttachment, differenceAttachment]
      )
    }
  }
  
  
  /// Used when the image size has no width or no height to generated the default empty image
  private static func emptyImage() -> UIImage {
    let label = UILabel(frame: CGRect(x: 0, y: 0, width: 400, height: 80))
    label.backgroundColor = .red
    label.text = "Error: No image could be generated for this view as its size was zero. Please set an explicit size in the test."
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
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match. [98-99% mimics the precision of the human eye.](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e)
  ///   - scale: The scale of the reference image stored on disk.
  public static func image(precision: Float = 1, perceptualPrecision: Float = 1, scale: CGFloat? = nil) -> Snapshotting {
    return .init(
      pathExtension: "png",
      diffing: .image(precision: precision, perceptualPrecision: perceptualPrecision, scale: scale)
    )
  }
}

// remap snapshot & reference to same colorspace
private let imageContextColorSpace = CGColorSpace(name: CGColorSpace.sRGB)
private let imageContextBitsPerComponent = 8
private let imageContextBytesPerPixel = 4

private func compare(_ old: UIImage, _ new: UIImage, precision: Float, perceptualPrecision: Float) -> String? {
  guard let oldCgImage = old.cgImage else {
    return "Reference image could not be loaded."
  }
  guard let newCgImage = new.cgImage else {
    return "Newly-taken snapshot could not be loaded."
  }
  guard newCgImage.width != 0, newCgImage.height != 0 else {
    return "Newly-taken snapshot is empty."
  }
  guard oldCgImage.width == newCgImage.width, oldCgImage.height == newCgImage.height else {
    return "Newly-taken snapshot@\(new.size) does not match reference@\(old.size)."
  }
  let pixelCount = oldCgImage.width * oldCgImage.height
  let byteCount = imageContextBytesPerPixel * pixelCount
  var oldBytes = [UInt8](repeating: 0, count: byteCount)
  guard let oldData = context(for: oldCgImage, data: &oldBytes)?.data else {
    return "Reference image's data could not be loaded."
  }
  if let newContext = context(for: newCgImage), let newData = newContext.data {
    if memcmp(oldData, newData, byteCount) == 0 { return nil }
  }
  var newerBytes = [UInt8](repeating: 0, count: byteCount)
  guard
    let pngData = new.pngData(),
    let newerCgImage = UIImage(data: pngData)?.cgImage,
    let newerContext = context(for: newerCgImage, data: &newerBytes),
    let newerData = newerContext.data
  else {
    return "Newly-taken snapshot's data could not be loaded."
  }
  if memcmp(oldData, newerData, byteCount) == 0 { return nil }
  if precision >= 1, perceptualPrecision >= 1 {
    return "Newly-taken snapshot does not match reference."
  }
  if perceptualPrecision < 1, #available(iOS 11.0, tvOS 11.0, *) {
    return perceptuallyCompare(
      CIImage(cgImage: oldCgImage),
      CIImage(cgImage: newCgImage),
      pixelPrecision: precision,
      perceptualPrecision: perceptualPrecision
    )
  } else {
    let byteCountThreshold = Int((1 - precision) * Float(byteCount))
    var differentByteCount = 0
    fastForEach(in: 0..<byteCount) { offset in
      if oldBytes[offset] != newerBytes[offset] {
        differentByteCount += 1
      }
    }
    if differentByteCount > byteCountThreshold {
      let actualPrecision = 1 - Float(differentByteCount) / Float(byteCount)
      return "Actual image precision \(actualPrecision) is less than required \(precision)"
    }
  }
  return nil
}

private func context(for cgImage: CGImage, data: UnsafeMutableRawPointer? = nil) -> CGContext? {
  let bytesPerRow = cgImage.width * imageContextBytesPerPixel
  guard
    let colorSpace = imageContextColorSpace,
    let context = CGContext(
      data: data,
      width: cgImage.width,
      height: cgImage.height,
      bitsPerComponent: imageContextBitsPerComponent,
      bytesPerRow: bytesPerRow,
      space: colorSpace,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
    else { return nil }

  context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
  return context
}

private func diff(_ old: UIImage, _ new: UIImage) -> UIImage {
  let width = max(old.size.width, new.size.width)
  let height = max(old.size.height, new.size.height)
  let scale = max(old.scale, new.scale)
  UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), true, scale)
  new.draw(at: .zero)
  old.draw(at: .zero, blendMode: .difference, alpha: 1)
  let differenceImage = UIGraphicsGetImageFromCurrentImageContext()!
  UIGraphicsEndImageContext()
  return differenceImage
}
#endif

#if os(iOS) || os(tvOS) || os(macOS)
import Accelerate.vImage
import CoreImage

func perceptuallyCompare(_ old: CIImage, _ new: CIImage, pixelPrecision: Float, perceptualPrecision: Float) -> String? {
  // Calculate the deltaE values. Each pixel is a value between 0-100.
  // 0 means no difference, 100 means completely opposite.
  let deltaOutputImage = old.applyingFilter("CILabDeltaE", parameters: ["inputImage2": new])
  // Setting the working color space and output color space to NSNull disables color management. This is appropriate when the output
  // of the operations is computational instead of an image intended to be displayed.
  let context = CIContext(options: [.workingColorSpace: NSNull(), .outputColorSpace: NSNull()])
  guard let buffer = deltaOutputImage.render(extent: deltaOutputImage.extent, context: context) else {
    return "Newly-taken snapshot could not be processed."
  }
  defer { buffer.free() }
  let deltaThreshold = (1 - perceptualPrecision) * 100
  var failingPixelCount: Int = 0
  var maximumDeltaE: Float = 0
  // rowBytes must be a multiple of 8, so vImage_Buffer pads the end of each row with bytes to meet the multiple of 0 requirement.
  // We must do 2D iteration of the vImage_Buffer in order to avoid loading the padding garbage bytes at the end of each row.
  fastForEach(in: 0..<Int(buffer.height)) { line in
    let lineOffset = buffer.rowBytes * line
    fastForEach(in: 0..<Int(buffer.width)) { column in
      let columnOffset = lineOffset + column * MemoryLayout<Float>.size
      let deltaE = buffer.data.load(fromByteOffset: columnOffset, as: Float.self)
      if deltaE > deltaThreshold {
        failingPixelCount += 1
      }
      maximumDeltaE = max(maximumDeltaE, deltaE)
    }
  }
  let failingPixelPercent = Float(failingPixelCount) / Float(deltaOutputImage.extent.width * deltaOutputImage.extent.height)
  let actualPixelPrecision = 1 - failingPixelPercent
  guard actualPixelPrecision < pixelPrecision else { return nil }
  // The actual perceptual precision is the perceptual precision of the pixel with the highest DeltaE.
  // DeltaE is in a 0-100 scale, so we need to divide by 100 to transform it to a percentage.
  let minimumPerceptualPrecision = 1 - maximumDeltaE / 100
  return """
  Actual image precision \(actualPixelPrecision) is less than required \(pixelPrecision)
  Minimum perceptual precision \(minimumPerceptualPrecision) is less than required \(perceptualPrecision)
  """
}

extension CIImage {
  func render(extent: CGRect, context: CIContext, format: CIFormat = CIFormat.Rh) -> vImage_Buffer? {
    // Some hardware configurations (virtualized CPU renderers) do not support 32-bit float output formats,
    // so use a compatible 16-bit float format and convert the output value to 32-bit floats.
    guard var buffer16 = try? vImage_Buffer(width: Int(extent.width), height: Int(extent.height), bitsPerPixel: 16) else { return nil }
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
      var buffer32 = try? vImage_Buffer(width: Int(buffer16.width), height: Int(buffer16.height), bitsPerPixel: 32),
      vImageConvert_Planar16FtoPlanarF(&buffer16, &buffer32, 0) == kvImageNoError
    else { return nil }
    return buffer32
  }
}
#endif

/// When the compiler doesn't have optimizations enabled, like in test targets, a `while` loop is significantly faster than a `for` loop
/// for iterating through the elements of a memory buffer. Details can be found in [SR-6983](https://github.com/apple/swift/issues/49531#issuecomment-1108286654)
func fastForEach(in range: Range<Int>, _ body: (Int) -> Void) {
  var index = range.lowerBound
  while index < range.upperBound {
    body(index)
    index += 1
  }
}
