#if os(macOS)
import Cocoa
import WebKit

extension Strategy {
  public static var view: Strategy<NSView, NSImage> {
    return .view(precision: 1)
  }

  public static func view(precision: Float) -> Strategy<NSView, NSImage> {
    return Strategy.image(precision: precision).contramap {
      precondition(!($0 is WKWebView), """
WKWebView must be snapshot using the "webView" strategy.

    assertSnapshot(matching: view, with: .webView)
""")

      return NSImage(data: $0.dataWithPDF(inside: $0.bounds))!
    }
  }
}

extension NSView: DefaultDiffable {
  public static let defaultStrategy: Strategy<NSView, NSImage> = .view
}
#endif
