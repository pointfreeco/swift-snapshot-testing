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

//      let superview = view.superview
//      defer { superview?.addSubview(self) }
      let window = ScaledWindow()
      window.appearance = NSAppearance.init(named: NSAppearance.Name.aqua)
      window.contentView = NSView()
      window.contentView?.frame = view.bounds
      window.contentView?.addSubview(view)
      window.makeKey()

      return view.snapshot ?? Async { callback in
        addImagesForRenderedViews(window.contentView!).sequence().run { views in
          let image = NSImage(data: window.contentView!.dataWithPDF(inside: window.contentView!.bounds))!
          image.size = .init(width: image.size.width, height: image.size.height)
          callback(image)
          views.forEach { $0.removeFromSuperview() }
          view.frame.size = initialSize

          view.removeFromSuperview()
//          window.contentView?.removesub .addSubview(view)
        }
      }
    }
  }
}

extension Snapshotting where Value == NSView, Format == String {
  /// A snapshot strategy for comparing views based on a recursive description of their properties and hierarchies.
  public static var recursiveDescription: Snapshotting<NSView, String> {
    return SimplySnapshotting.lines.pullback { view in

      view.display()
      view.layout()

      return purgePointers(
        view.perform(Selector(("_subtreeDescription"))).retain().takeUnretainedValue()
          as! String
      )
    }
  }
}
#endif
