#if os(macOS)
import Cocoa

extension Snapshotting where Value == NSView, Format == NSImage {
  /// A snapshot strategy for comparing views based on pixel equality.
  public static var image: Snapshotting {
    return .image()
  }

  /// A snapshot strategy for comparing views based on pixel equality.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - size: A view size override.
  public static func image(precision: Float = 1, size: CGSize? = nil) -> Snapshotting {
    return SimplySnapshotting.image(precision: precision).asyncPullback { view in
      let initialSize = view.frame.size
      if let size = size { view.frame.size = size }
      guard view.frame.width > 0, view.frame.height > 0 else {
        fatalError("View not renderable to image at size \(view.frame.size)")
      }
      return view.snapshot ?? Async { callback in
        addImagesForRenderedViews(view).sequence().run { views in
          let image = NSImage(data: view.dataWithPDF(inside: view.bounds))!
          image.size = .init(width: image.size.width, height: image.size.height)
          callback(image)
          views.forEach { $0.removeFromSuperview() }
          view.frame.size = initialSize
        }
      }
    }
  }
}

extension Snapshotting where Value == NSView, Format == String {
  /// A snapshot strategy for comparing views based on a recursive description of their properties and hierarchies.
  public static var recursiveDescription: Snapshotting<NSView, String> {
    return SimplySnapshotting.lines.pullback { view in
      return purgePointers(
        view.perform(Selector(("_subtreeDescription"))).retain().takeUnretainedValue()
          as! String
      )
    }
  }
}
#endif
