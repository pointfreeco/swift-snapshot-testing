#if os(macOS)
import Cocoa
import WebKit

extension Strategy {
  public static var recursiveDescription: Strategy<NSView, String> {
    return Strategy.lines.pullback { view in
      return purgePointers(
        view.perform(Selector(("_subtreeDescription"))).retain().takeUnretainedValue()
          as! String
      )
    }
  }

  public static var nsView: Strategy<NSView, NSImage> {
    return .nsView(precision: 1)
  }

  public static func nsView(precision: Float) -> Strategy<NSView, NSImage> {
    return Strategy.image.pullback {
      let image = NSImage(data: $0.dataWithPDF(inside: $0.bounds))!
      let scale = NSScreen.main!.backingScaleFactor
      image.size = .init(width: image.size.width * 2.0 / scale, height: image.size.height * 2.0 / scale)
      return image
    }
  }

  public static var view: Strategy<NSView, NSImage> {
    return .view(precision: 1)
  }

  public static func view(precision: Float) -> Strategy<NSView, NSImage> {
    let imageStrategy = Strategy.image(precision: precision)
    return .init(
      pathExtension: imageStrategy.pathExtension,
      diffable: imageStrategy.diffable
    ) { view -> Async<NSImage> in
      if let webView = view as? WKWebView {
        if #available(OSX 10.13, *) {
          return Strategy.webView(precision: precision).snapshotToDiffable(webView)
        } else {
          fatalError()
        }
      } else {
        return Strategy.nsView(precision: precision).snapshotToDiffable(view)
      }
    }
  }
}

extension NSView: DefaultDiffable {
  public static let defaultStrategy: Strategy<NSView, NSImage> = .view
}
#endif
