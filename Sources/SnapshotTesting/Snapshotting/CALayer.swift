#if os(macOS)
import Cocoa

extension Snapshotting where Value == CALayer, Format == NSImage {
  /// A snapshot strategy for comparing layers based on pixel equality.
  public static var image: Snapshotting {
    return .image(precision: 1, subpixelThreshold: 0)
  }

  /// A snapshot strategy for comparing layers based on pixel equality.
  ///
  /// - Parameter precision: The percentage of pixels that must match.
  /// - Parameter subpixelThreshold: The byte-value threshold at which two subpixels are considered different.
  public static func image(precision: Float, subpixelThreshold: UInt8) -> Snapshotting {
    return SimplySnapshotting.image(precision: precision, subpixelThreshold: subpixelThreshold).pullback { layer in
      let image = NSImage(size: layer.bounds.size)
      image.lockFocus()
      let context = NSGraphicsContext.current!.cgContext
      layer.setNeedsLayout()
      layer.layoutIfNeeded()
      layer.render(in: context)
      image.unlockFocus()
      return image
    }
  }
}
#elseif os(iOS) || os(tvOS)
import UIKit

extension Snapshotting where Value == CALayer, Format == UIImage {
  /// A snapshot strategy for comparing layers based on pixel equality.
  public static var image: Snapshotting {
    return .image()
  }

  /// A snapshot strategy for comparing layers based on pixel equality.
  ///
  /// - Parameter precision: The percentage of pixels that must match.
  /// - Parameter subpixelThreshold: The byte-value threshold at which two subpixels are considered different.
    public static func image(precision: Float = 1, subpixelThreshold: UInt8 = 0, traits: UITraitCollection = .init())
    -> Snapshotting {
      return SimplySnapshotting.image(precision: precision, subpixelThreshold: subpixelThreshold, scale: traits.displayScale).pullback { layer in
        renderer(bounds: layer.bounds, for: traits).image { ctx in
          layer.setNeedsLayout()
          layer.layoutIfNeeded()
          layer.render(in: ctx.cgContext)
        }
      }
  }
}
#endif
