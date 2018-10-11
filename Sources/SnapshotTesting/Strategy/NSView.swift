#if os(macOS)
import Cocoa

extension Strategy {
  public static var view: Strategy<NSView, NSImage> {
    return Strategy.image.pre { view in
      guard
        let image = NSImage(data: view.dataWithPDF(inside: view.bounds)),
        let scale = NSScreen.main?.backingScaleFactor
        else { return nil }
      image.size = .init(width: image.size.width * 2.0 / scale, height: image.size.height * 2.0 / scale)
      return image
    }
  }
}

extension NSView: DefaultDiffable {
  public static let defaultStrategy: Strategy<NSView, NSImage> = .view
}
#endif
