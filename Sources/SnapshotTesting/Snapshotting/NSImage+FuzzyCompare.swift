//
//  NSImage+FuzzyCompare.swift
//
//  Created by Jason William Staiert on 6/22/21.
//

#if os(macOS)
import Cocoa
import CoreGraphics
import SnapshotCompare
import XCTest

extension Diffing where Value == NSImage {

  /// A pixel-diffing strategy for NSImage's which requires a exact match.
  public static let fuzzyImage = Diffing.fuzzyImage(
    maxAbsoluteComponentDifference: 0.0,
    maxAverageAbsoluteComponentDifference: 0.0
  )

  /// A pixel-diffing strategy for NSImage that allows customizing how precise
  /// the matching must be.
  ///
  /// - Parameter maxAbsoluteComponentDifference: A value between 0 and positive
  /// infinity, where 0 means each component of every pixel must match exactly.
  /// Values greater than 0 will match pixels with an absolute difference equal
  /// to or less that value.
  /// - Parameter maxAverageAbsoluteComponentDifference: A value between 0 and
  /// positive infinity, where 0 means each component of every pixel must match
  /// exactly. Values greater than 0 will match images with an average absolute
  /// difference equal to or less than that value.
  /// - Returns: A new diffing strategy.
  public static func fuzzyImage(
    maxAbsoluteComponentDifference: Double,
    maxAverageAbsoluteComponentDifference: Double
  ) -> Diffing {
    return .init(
      toData: { NSImagePNGRepresentation($0)! },
      fromData: { NSImage(data: $0)! }
    ) { old, new in

      let result = compare(old, new, maxAbsoluteComponentDifference, maxAverageAbsoluteComponentDifference)

      if result.passed {
        return nil
      }

      let difference = SnapshotTesting.diff(old, new)

      let message = new.size == old.size
        ? "Newly-taken snapshot does not match reference. \(result.message)"
        : "Newly-taken snapshot@\(new.size) does not match reference@\(old.size). \(result.message)"
      return (
        message,
        [XCTAttachment(image: old), XCTAttachment(image: new), XCTAttachment(image: difference)]
      )
    }
  }
}

extension Snapshotting where Value == NSImage, Format == NSImage {

  /// A snapshot strategy for comparing images based on pixel equality.
  public static var fuzzyImage: Snapshotting {
    return .fuzzyImage(
      maxAbsoluteComponentDifference: 0.0,
      maxAverageAbsoluteComponentDifference: 0.0
    )
  }

  /// A snapshot strategy for comparing images based on pixel equality.
  ///
  /// - Parameter maxAbsoluteComponentDifference: A value between 0 and positive
  /// infinity, where 0 means each component of every pixel must match exactly.
  /// Values greater than 0 will match pixels with an absolute difference equal
  /// to or less that value.
  /// - Parameter maxAverageAbsoluteComponentDifference: A value between 0 and
  /// positive infinity, where 0 means each component of every pixel must match
  /// exactly. Values greater than 0 will match images with an average absolute
  /// difference equal to or less than that value.
  public static func fuzzyImage(
    maxAbsoluteComponentDifference: Double,
    maxAverageAbsoluteComponentDifference: Double
  ) -> Snapshotting {
    return .init(
      pathExtension: "png",
      diffing: .fuzzyImage(
        maxAbsoluteComponentDifference: maxAbsoluteComponentDifference,
        maxAverageAbsoluteComponentDifference: maxAverageAbsoluteComponentDifference
      )
    )
  }
}

private func NSImagePNGRepresentation(_ image: NSImage) -> Data? {
  guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
  let rep = NSBitmapImageRep(cgImage: cgImage)
  rep.size = image.size
  return rep.representation(using: .png, properties: [:])
}

private func compare(
  _ old: NSImage,
  _ new: NSImage,
  _ maxACD: Double,
  _ maxAACD: Double
) -> (passed: Bool, message: String) {

  guard let oldCgImage = old.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    return (false, "old: CGImage from NSImage failed.")
  }

  guard let oldContext = context(for: oldCgImage) else {
    return (false, "old: CGContext from CGImage failed.")
  }

  guard let newCgImage = new.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    return (false, "new: CGImage from NSImage failed.")
  }

  guard let newContext = context(for: newCgImage) else {
    return (false, "new: CGContext from CGImage failed.")
  }

  guard oldContext.width != 0 else { return (false, "old: CGContext width = 0.") }
  guard newContext.width != 0 else { return (false, "new: CGContext width = 0.") }
  guard oldContext.width == newContext.width else { return (false, "new+old: CGContext width not equal.") }

  guard oldContext.height != 0 else { return (false, "old: CGContext height = 0.") }
  guard newContext.height != 0 else { return (false, "new: CGContext height = 0.") }
  guard oldContext.height == newContext.height else { return (false, "new+old: CGContext height not equal.") }

  if oldContext.bytesPerRow == newContext.bytesPerRow {

    guard let oldData = oldContext.data else { return (false, "old: CGContext data doesn't exist.") }
    guard let newData = newContext.data else { return (false, "new: CGContext data doesn't exist.") }
    let byteCount = oldContext.height * oldContext.bytesPerRow
    if memcmp(oldData, newData, byteCount) == 0 { return (true, "") }
  }

  return fuzzyCompare(
    a: oldContext,
    b: newContext,
    maxAbsoluteComponentDifference: maxACD,
    maxAverageAbsoluteComponentDifference: maxAACD
  )
}

private func context(for cgImage: CGImage) -> CGContext? {
  guard
    let space = cgImage.colorSpace,
    let context = CGContext(
      data: nil,
      width: cgImage.width,
      height: cgImage.height,
      bitsPerComponent: cgImage.bitsPerComponent,
      bytesPerRow: cgImage.bytesPerRow,
      space: space,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
  else { return nil }

  context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
  return context
}

private func diff(_ old: NSImage, _ new: NSImage) -> NSImage {
  let oldCiImage = CIImage(cgImage: old.cgImage(forProposedRect: nil, context: nil, hints: nil)!)
  let newCiImage = CIImage(cgImage: new.cgImage(forProposedRect: nil, context: nil, hints: nil)!)
  let differenceFilter = CIFilter(name: "CIDifferenceBlendMode")!
  differenceFilter.setValue(oldCiImage, forKey: kCIInputImageKey)
  differenceFilter.setValue(newCiImage, forKey: kCIInputBackgroundImageKey)
  let maxSize = CGSize(
    width: max(old.size.width, new.size.width),
    height: max(old.size.height, new.size.height)
  )
  let rep = NSCIImageRep(ciImage: differenceFilter.outputImage!)
  let difference = NSImage(size: maxSize)
  difference.addRepresentation(rep)
  return difference
}
#endif
