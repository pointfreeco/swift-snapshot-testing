#if os(macOS)
import Cocoa

extension Snapshotting where Value == NSViewController, Format == NSImage {
  /// A snapshot strategy for comparing view controller views based on pixel equality.
  public static var image: Snapshotting {
    return .image()
  }

  /// A snapshot strategy for comparing view controller views based on pixel equality.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - subpixelThreshold: The byte-value threshold at which two subpixels are considered different.
  ///   - size: A view size override.
  public static func image(precision: Float = 1, subpixelThreshold: UInt8 = 0, size: CGSize? = nil) -> Snapshotting {
    return Snapshotting<NSView, NSImage>.image(precision: precision, subpixelThreshold: subpixelThreshold, size: size).pullback { $0.view }
  }
}

extension Snapshotting where Value == NSViewController, Format == String {
  /// A snapshot strategy for comparing view controller views based on a recursive description of their properties and hierarchies.
  public static var recursiveDescription: Snapshotting {
    return Snapshotting<NSView, String>.recursiveDescription.pullback { $0.view }
  }
}
#endif
