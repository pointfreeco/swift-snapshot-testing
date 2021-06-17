#if os(iOS) || os(macOS)
import PDFKit
#endif

#if os(macOS)
import Cocoa

extension Snapshotting where Value == CALayer, Format == NSImage {
  /// A snapshot strategy for comparing layers based on pixel equality.
  public static var image: Snapshotting {
    return .image(precision: 1)
  }

  /// A snapshot strategy for comparing layers based on pixel equality.
  ///
  /// - Parameter precision: The percentage of pixels that must match.
  public static func image(precision: Float) -> Snapshotting {
    return SimplySnapshotting.image(precision: precision).pullback { layer in
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
  /// A snapshot strategy for comparing layers based on pixel equality, persisted as PNG.
  public static var image: Snapshotting {
    return .image()
  }

  /// A snapshot strategy for comparing layers based on pixel equality, persisted as PNG.
  ///
  /// - Parameter precision: The percentage of pixels that must match.
  public static func image(precision: Float = 1, traits: UITraitCollection = .init())
    -> Snapshotting {
      return SimplySnapshotting.image(precision: precision, scale: traits.displayScale).pullback { layer in
        imageRenderer(bounds: layer.bounds, traits: traits).image { ctx in
          layer.setNeedsLayout()
          layer.layoutIfNeeded()
          layer.render(in: ctx.cgContext)
        }
      }
  }
}
#endif

#if os(iOS)
@available(iOS 11.0, *)
extension Snapshotting where Value == CALayer, Format == PDFDocument {
  /// A snapshot strategy for comparing layers based on pixel equality, persisted as PDF.
  public static var pdf: Snapshotting {
    return .pdf()
  }

  /// A snapshot strategy for comparing layers based on pixel equality, persisted as PDF.
  ///
  /// - Parameter precision: The percentage of pixels that must match.
  public static func pdf(precision: Float = 1) -> Snapshotting {
    return SimplySnapshotting.rasterized(precision: precision).pullback { layer in
      let data = pdfRenderer(bounds: layer.bounds).pdfData { ctx in
        ctx.beginPage()
        layer.setNeedsLayout()
        layer.layoutIfNeeded()
        layer.render(in: ctx.cgContext)
      }
      return PDFDocument(data: data)!
    }
  }
}
#endif
