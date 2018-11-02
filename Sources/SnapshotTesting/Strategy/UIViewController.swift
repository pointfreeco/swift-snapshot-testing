#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

extension Strategy where A == UIViewController, B == UIImage {
  public static var uiViewController: Strategy {
    return .uiViewController(precision: 1)
  }

  public static func uiViewController(precision: Float) -> Strategy {
    return Strategy<UIView, UIImage>.view(precision: precision).pullback { $0.view }
  }
}

extension UIViewController: DefaultDiffable {
  public static let defaultStrategy: Strategy<UIViewController, UIImage> = .uiViewController
}
#endif
