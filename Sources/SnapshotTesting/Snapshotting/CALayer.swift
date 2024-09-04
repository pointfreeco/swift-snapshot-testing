#if os(macOS)
import Cocoa

extension Snapshotting where Value == CALayer, Format == NSImage {
  /// A snapshot strategy for comparing layers based on pixel equality.
  public static var image: Snapshotting {
    return .image(precision: 1, format: imageFormat)
  }

  /// A snapshot strategy for comparing layers based on pixel equality.
  ///
  /// - Parameter precision: The percentage of pixels that must match.
  public static func image(precision: Float, format: ImageFormat) -> Snapshotting {
    return SimplySnapshotting.image(precision: precision, format: format).pullback { layer in
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
    return .image(format: imageFormat)
  }

  /// A snapshot strategy for comparing layers based on pixel equality.
  ///
  /// - Parameter precision: The percentage of pixels that must match.
  public static func image(precision: Float = 1, traits: UITraitCollection = .init(), format: ImageFormat)
    -> Snapshotting {
      return SimplySnapshotting.image(precision: precision, scale: traits.displayScale, format: format).pullback { layer in
        renderer(bounds: layer.bounds, for: traits).image { ctx in
          layer.setNeedsLayout()
          layer.layoutIfNeeded()
          layer.render(in: ctx.cgContext)
        }
      }
  }
}
#endif
