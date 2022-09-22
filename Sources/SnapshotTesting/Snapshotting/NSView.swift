#if os(macOS)
import Cocoa

extension Snapshotting where Value == NSView, Format == NSImage {
  /// A snapshot strategy for comparing views based on pixel equality.
  public static var image: Snapshotting {
    return .image()
  }

  /// A snapshot strategy for comparing views based on pixel equality.
  ///
  /// >This function calls to `NSView.cacheDisplay()` which has side-effects that cannot be undone. Under some circumstances
  /// >subviews will be added (e.g. for `NSButton`-views) and `NSView.needsLayout` will be set to `false`. Keep that in mind
  /// >when asserting with `.image` and `.recursiveDescription` within the same test.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match. [98-99% mimics the precision of the human eye.](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e)
  ///   - size: A view size override.
  ///   - appearance: The appearance to use when drawing the view. Pass `nil` to use the view’s existing appearance.
  ///   - windowForDrawing: The choice of window to use when drawing the view. Pass `nil` to ignore.
  public static func image(
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    size: CGSize? = nil,
    appearance: NSAppearance? = NSAppearance(named: .aqua),
    windowForDrawing: GenericWindow? = nil
  ) -> Snapshotting {
    return SimplySnapshotting.image(precision: precision, perceptualPrecision: perceptualPrecision).asyncPullback { view in
      let initialFrame = view.frame
      if let size = size { view.frame.size = size }
      guard view.frame.width > 0, view.frame.height > 0 else {
        fatalError("View not renderable to image at size \(view.frame.size)")
      }

      let initialAppearance = view.appearance
      if let appearance = appearance {
        view.appearance = appearance
      }

      if let windowForDrawing = windowForDrawing {
        precondition(
          view.window == nil,
          """
          If choosing to draw the view using a new window, the view must not already be attached to an existing window. \
          (We wouldn’t be able to easily restore the view and all its associated constraints to the original window \
          after moving it to the new window.)
          """
        )
        windowForDrawing.contentView = NSView()
        windowForDrawing.contentView?.addSubview(view)
      }

      return view.snapshot ?? Async { callback in
        addImagesForRenderedViews(view).sequence().run { views in
          let bitmapRep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
          view.cacheDisplay(in: view.bounds, to: bitmapRep)
          let image = NSImage(size: view.bounds.size)
          image.addRepresentation(bitmapRep)
          callback(image)
          views.forEach { $0.removeFromSuperview() }
          view.appearance = initialAppearance
          view.frame = initialFrame

          if windowForDrawing != nil {
            view.removeFromSuperview()
            view.layer = nil
            view.subviews.forEach { subview in
              subview.layer = nil
            }
            // This is to maintain compatibility with `recursiveDescription` because the current
            // test snapshots expect `.needsLayout = false` and for some apple magic reason
            // `view.needsLayout = false` does not do anything, but this does.
            let bitmapRep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
            view.cacheDisplay(in: view.bounds, to: bitmapRep)
          }
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

/// A NSWindow which can be configured in a deterministic way.
public final class GenericWindow: NSWindow {
  public init(backingScaleFactor: CGFloat = 2.0, colorSpace: NSColorSpace? = nil) {
    self._backingScaleFactor = backingScaleFactor
    self._explicitlySpecifiedColorSpace = colorSpace

    super.init(contentRect: NSRect.zero, styleMask: [], backing: .buffered, defer: true)
  }

  private let _explicitlySpecifiedColorSpace: NSColorSpace?
  private var _systemSpecifiedColorspace: NSColorSpace?

  private let _backingScaleFactor: CGFloat
  public override var backingScaleFactor: CGFloat {
    return _backingScaleFactor
  }

  public override var colorSpace: NSColorSpace? {
    get {
      _explicitlySpecifiedColorSpace ?? self._systemSpecifiedColorspace
    }
    set {
      self._systemSpecifiedColorspace = newValue
    }
  }
}

extension GenericWindow {
  static let ci = GenericWindow(backingScaleFactor: 1.0, colorSpace: .genericRGB)
}
#endif
