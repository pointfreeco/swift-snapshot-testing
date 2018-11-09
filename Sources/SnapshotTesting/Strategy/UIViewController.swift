#if os(iOS) || os(tvOS)
import UIKit

extension Strategy where Snapshottable == UIViewController, Format == UIImage {
  public static var image: Strategy {
    return .image(precision: 1, size: nil)
  }

  public static func image(precision: Float) -> Strategy {
    return .image(precision: precision, size: nil)
  }

  public static func image(precision: Float = 1, size: CGSize) -> Strategy {
    return .image(precision: precision, size: .some(size))
  }

  private static func image(precision: Float, size: CGSize?) -> Strategy {
    return Strategy<UIView, UIImage>.image(precision: precision, size: size).pullback { $0.view }
  }
}

extension Strategy where Snapshottable == UIViewController, Format == String {
  public static var recursiveDescription: Strategy {
    return Strategy<UIView, String>.recursiveDescription.pullback { $0.view }
  }
}

extension UIViewController: DefaultSnapshottable {
  public static let defaultStrategy: Strategy<UIViewController, UIImage> = .image
}
#endif
