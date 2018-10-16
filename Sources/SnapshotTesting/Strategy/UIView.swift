#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
import WebKit

extension Strategy {
  public static var view: Strategy<UIView, UIImage> {
    return .view(precision: 1)
  }

  public static func view(precision: Float) -> Strategy<UIView, UIImage> {
    return Strategy.layer(precision: precision).contramap {
      precondition(!($0 is WKWebView), """
WKWebView must be snapshot using the "webView" strategy.

    assertSnapshot(matching: view, with: .webView)
""")

      return $0.layer
    }
  }
}

extension UIView: DefaultDiffable {
  public static let defaultStrategy: Strategy<UIView, UIImage> = .view
}
#endif
