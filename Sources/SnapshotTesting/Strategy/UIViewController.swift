#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

extension Strategy {
  public static var viewController: Strategy<UIViewController, UIImage> {
    return .viewController(precision: 1)
  }

  public static func viewController(precision: Float) -> Strategy<UIViewController, UIImage> {
    return Strategy.view(precision: precision).contramap { $0.view }
  }
}

extension UIViewController: DefaultDiffable {
  public static let defaultStrategy: Strategy<UIViewController, UIImage> = .viewController
}
#endif
