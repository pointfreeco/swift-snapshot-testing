#if os(macOS)
import Cocoa
import WebKit

extension Strategy {
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
        let image = NSImage(data: view.dataWithPDF(inside: view.bounds))!
        let scale = NSScreen.main!.backingScaleFactor
        image.size = .init(width: image.size.width * 2.0 / scale, height: image.size.height * 2.0 / scale)
        return imageStrategy.snapshotToDiffable(image)
      }
    }
  }
}

extension NSView: DefaultDiffable {
  public static let defaultStrategy: Strategy<NSView, NSImage> = .view
}
#endif
