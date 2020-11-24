#if os(macOS)
import Cocoa

extension Snapshotting where Value == NSView, Format == NSImage {
  /// A snapshot strategy for comparing views based on pixel equality.
  public static var image: Snapshotting {
    return .image()
  }

  /// The choice of window to use when drawing the view.
  public enum WindowForDrawing {
    /// Adds the view to a new window with the specified properties.
    ///
    /// The view will be removed from the new window after drawing.
    ///
    /// - Precondition: The view must not already be attached to an existing window. (We wouldn’t be able to easily restore
    ///                 the view and all its associated constraints to the original window after moving it to the new window.)"
    case newWindow(backingScaleFactor: CGFloat)

    /// Uses the view’s existing window.
    case existingWindow
  }

  /// A snapshot strategy for comparing views based on pixel equality.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - size: A view size override.
  ///   - appearance: The appearance to use when drawing the view. Pass `nil` to use the view’s existing appearance.
  ///   - windowForDrawing: The choice of window to use when drawing the view.
  public static func image(
    precision: Float = 1,
    size: CGSize? = nil,
    appearance: NSAppearance? = NSAppearance(named: .aqua),
    windowForDrawing: WindowForDrawing = .newWindow(backingScaleFactor: 1)
  ) -> Snapshotting {
    return SimplySnapshotting.image(precision: precision).asyncPullback { view in
      let originalFrame = view.frame

      let newWindow: NSWindow?
      switch windowForDrawing {
      case .newWindow(let backingScaleFactor):
        precondition(
          view.window == nil,
          """
          If choosing to draw the view using a new window, the view must not already be attached to an existing window. \
          (We wouldn’t be able to easily restore the view and all its associated constraints to the original window \
          after moving it to the new window.)
          """
        )
        let scaledWindow = ScaledWindow(
          backingScaleFactor: backingScaleFactor,
          viewToSnapshot: view
        )
        newWindow = scaledWindow

      case .existingWindow:
        precondition(
          view.window != nil,
          "The view must be contained in a window if choosing to draw the view using an existing window."
        )
        newWindow = nil
      }

      let originalAppearance = view.appearance
      if let appearance = appearance {
        view.appearance = appearance
      }

      if let size = size { view.frame.size = size }
      view.layoutSubtreeIfNeeded()
      guard view.frame.width > 0, view.frame.height > 0 else {
        fatalError("View not renderable to image at size \(view.frame.size)")
      }

      return view.snapshot ?? Async { callback in
        addImagesForRenderedViews(view).sequence().run { views in
          let bitmapRep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
          view.cacheDisplay(in: view.bounds, to: bitmapRep)

          let image = NSImage(size: view.bounds.size)
          image.addRepresentation(bitmapRep)
          callback(image)

          views.forEach { $0.removeFromSuperview() }
          if newWindow != nil { view.removeFromSuperview() }
          view.appearance = originalAppearance
          view.frame = originalFrame
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

fileprivate final class ScaledWindow: NSWindow {
  init(backingScaleFactor: CGFloat, viewToSnapshot: NSView) {
    self._backingScaleFactor = backingScaleFactor

    super.init(contentRect: NSRect.zero,
               styleMask: [],
               backing: .buffered,
               defer: true)

    let contentView = NSView()
    contentView.wantsLayer = true
    self.contentView = contentView

    contentView.addSubview(viewToSnapshot)
  }

  private let _backingScaleFactor: CGFloat
  override var backingScaleFactor: CGFloat {
    return _backingScaleFactor
  }
}
#endif
