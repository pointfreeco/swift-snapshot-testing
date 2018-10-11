#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

extension Strategy {
  public static var viewController: Strategy<UIViewController, UIImage> {
    return Strategy.view.pre { $0.view }
  }
}

extension UIViewController: DefaultDiffable {
  public static let defaultStrategy: Strategy<UIViewController, UIImage> = .viewController
}
#endif
