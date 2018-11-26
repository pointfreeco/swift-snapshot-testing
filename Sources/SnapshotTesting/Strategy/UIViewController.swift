#if os(iOS) || os(tvOS)
import UIKit

extension Strategy where Snapshottable == UIViewController, Format == UIImage {
  public static var image: Strategy {
    return .image(on: .iPhone8)
  }

  public static func image(
    drawingHierarchyInKeyWindow: Bool = false,
    on config: ViewImageConfig,
    precision: Float = 1,
    traits: UITraitCollection = .iPhone8(.portrait)
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
