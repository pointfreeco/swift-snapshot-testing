#if os(iOS) || os(tvOS)
import UIKit

extension Strategy where Snapshottable == UIViewController, Format == UIImage {
  public static var image: Strategy {
    return .image()
  }

  public static func image(
    on config: ViewImageConfig = .init(),
    precision: Float = 1,
    traits: UITraitCollection = .init()
    )
    -> Strategy {

      return SimpleStrategy.image(precision: precision).asyncPullback { viewController in
        snapshotView(
          config: config,
          traits: traits,
          view: viewController.view,
          viewController: viewController
        )
      }
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
