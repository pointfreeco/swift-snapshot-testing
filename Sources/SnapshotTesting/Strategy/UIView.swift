#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
import WebKit

extension Strategy {
  public static var view: Strategy<UIView, UIImage> {
    return .view(precision: 1)
  }

  public static func view(precision: Float) -> Strategy<UIView, UIImage> {
    let imageStrategy = Strategy.image(precision: precision)
    return .init(
      pathExtension: imageStrategy.pathExtension,
      diffable: imageStrategy.diffable
    ) { view -> Async<UIImage> in
      if let webView = view as? WKWebView {
        return Strategy.webView(precision: precision).snapshotToDiffable(webView)
      } else {
        return Strategy.layer(precision: precision).snapshotToDiffable(view.layer)
      }
    }
  }
}

extension UIView: DefaultDiffable {
  public static let defaultStrategy: Strategy<UIView, UIImage> = .view
}
#endif
