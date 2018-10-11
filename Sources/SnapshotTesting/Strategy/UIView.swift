#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

extension Strategy {
  public static var view: Strategy<UIView, UIImage> {
    return Strategy.layer.pre { $0.layer }
  }
}

extension UIView: DefaultDiffable {
  public static let defaultStrategy: Strategy<UIView, UIImage> = .view
}
#endif
