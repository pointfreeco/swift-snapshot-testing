#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

extension Strategy {
  public static var uiViewController: Strategy<UIViewController, UIImage> {
    return .uiViewController(precision: 1)
  }

  public static func uiViewController(precision: Float) -> Strategy<UIViewController, UIImage> {
    return Strategy.uiView(precision: precision).contramap { $0.view }
  }
}

extension UIViewController: DefaultDiffable {
  public static let defaultStrategy: Strategy<UIViewController, UIImage> = .uiViewController
}
#endif
