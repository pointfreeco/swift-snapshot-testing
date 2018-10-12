#if os(macOS)
import Cocoa
import WebKit

extension Strategy {
  public static var view: Strategy<NSView, NSImage> {
    return Strategy.image.contramap { view in
      precondition(!(view is WKWebView), "TODO")

      let image = NSImage(data: view.dataWithPDF(inside: view.bounds))!
      let scale = NSScreen.main!.backingScaleFactor
      image.size = .init(width: image.size.width * 2.0 / scale, height: image.size.height * 2.0 / scale)
      return image
    }
  }
}

extension NSView: DefaultDiffable {
  public static let defaultStrategy: Strategy<NSView, NSImage> = .view
}
#endif
