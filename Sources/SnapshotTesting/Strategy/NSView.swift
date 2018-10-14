#if os(macOS)
import Cocoa
import WebKit

extension Strategy {
  public static var view: Strategy<NSView, NSImage> {
    return Strategy.image.contramap {
      precondition(!($0 is WKWebView), """
WKWebView must be snapshot using the "webView" strategy.

    assertSnapshot(matching: view, with: .webView)
""")

      let imageRepresentation = $0.bitmapImageRepForCachingDisplay(in: $0.bounds)!
      $0.cacheDisplay(in: $0.bounds, to: imageRepresentation)
      return NSImage(cgImage: imageRepresentation.cgImage!, size: $0.bounds.size)
    }
  }
}

extension NSView: DefaultDiffable {
  public static let defaultStrategy: Strategy<NSView, NSImage> = .view
}
#endif
