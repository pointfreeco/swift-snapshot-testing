//
//  UIImage+FuzzyCompare.swift
//
//  Created by Jason William Staiert on 6/22/21.
//

#if os(iOS) || os(tvOS)
import UIKit
import CoreGraphics
import SnapshotCompare
import XCTest

extension Diffing where Value == UIImage {

  /// A pixel-diffing strategy for NSImage's which requires a exact match.
  public static let fuzzyImage = Diffing.fuzzyImage(
    maxAbsoluteComponentDifference: 0.0,
    maxAverageAbsoluteComponentDifference: 0.0,
    scale: 0.0
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
    maxAverageAbsoluteComponentDifference: Double,
    scale: CGFloat?
  ) -> Diffing {

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
  public static var fuzzyImage: Snapshotting {
    return .fuzzyImage(
      maxAbsoluteComponentDifference: 0.0,
      maxAverageAbsoluteComponentDifference: 0.0,
      scale: 0.0
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
    maxAverageAbsoluteComponentDifference: Double,
    scale: CGFloat?
  ) -> Snapshotting {
    return .init(
      pathExtension: "png",
      diffing: .fuzzyImage(
        maxAbsoluteComponentDifference: maxAbsoluteComponentDifference,
        maxAverageAbsoluteComponentDifference: maxAverageAbsoluteComponentDifference,
        scale: scale
      )
    )
  }
}

private func compare(
  _ old: UIImage,
  _ new: UIImage,
  _ maxACD: Double,
  _ maxAACD: Double
) -> (passed: Bool, message: String) {

  guard let oldCgImage = old.cgImage else {
    return (false, "old: CGImage from NSImage failed.")
  }

  guard let oldContext = context(for: oldCgImage) else {
    return (false, "old: CGContext from CGImage failed.")
  }

  guard let newCgImage = new.cgImage else {
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
      data:               nil,
      width:              cgImage.width,
      height:             cgImage.height,
      bitsPerComponent:   cgImage.bitsPerComponent,
      bytesPerRow:        cgImage.width * 4,
      space:              space,
      bitmapInfo:         CGImageAlphaInfo.premultipliedLast.rawValue
    )
  else { return nil }
  context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
  return context
}

private func diff(_ old: UIImage, _ new: UIImage) -> UIImage {
  let width = max(old.size.width, new.size.width)
  let height = max(old.size.height, new.size.height)
  UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), true, 0)
  new.draw(at: .zero)
  old.draw(at: .zero, blendMode: .difference, alpha: 1)
  let differenceImage = UIGraphicsGetImageFromCurrentImageContext()!
  UIGraphicsEndImageContext()
  return differenceImage
}
#endif
