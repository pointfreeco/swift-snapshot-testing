#if os(iOS) || os(tvOS)
import UIKit

extension Strategy where A == UIViewController, B == UIImage {
  public static var image: Strategy {
    return .image(precision: 1)
  }

  public static func image(precision: Float) -> Strategy {
    return Strategy<UIView, UIImage>.image(precision: precision).pullback { $0.view }
  }
}

extension Strategy where A == UIViewController, B == String {
  public static var recursiveDescription: Strategy {
    return Strategy<UIView, String>.recursiveDescription.pullback { $0.view }
  }
}

extension UIViewController: DefaultDiffable {
  public static let defaultStrategy: Strategy<UIViewController, UIImage> = .image
}
#endif
