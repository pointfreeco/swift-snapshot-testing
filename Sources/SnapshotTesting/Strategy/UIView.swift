#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
import WebKit

extension Strategy {
  public static var recursiveDescription: Strategy<UIView, String> {
    return Strategy.lines.pullback { view in
      return purgePointers(
        view.perform(Selector(("recursiveDescription"))).retain().takeUnretainedValue()
          as! String
      )
    }
  }

  public static var uiView: Strategy<UIView, UIImage> {
    return .uiView(precision: 1)
  }

  public static func uiView(precision: Float) -> Strategy<UIView, UIImage> {
    return Strategy.layer.pullback { $0.layer }
  }

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
        return Strategy.uiView(precision: precision).snapshotToDiffable(view)
      }
    }
  }
}

extension UIView: DefaultDiffable {
  public static let defaultStrategy: Strategy<UIView, UIImage> = .view
}
#endif
