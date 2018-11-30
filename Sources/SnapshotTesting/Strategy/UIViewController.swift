#if os(iOS) || os(tvOS)
import UIKit

extension Strategy where Snapshottable == UIViewController, Format == UIImage {
  public static var image: Strategy {
    return .image()
  }

  public static func image(
    on config: ViewImageConfig,
    precision: Float = 1,
    size: CGSize? = nil,
    traits: UITraitCollection = .init()
    )
    -> Strategy {

      return SimpleStrategy.image(precision: precision).asyncPullback { viewController in
        snapshotView(
          config: size.map { .init(safeArea: config.safeArea, size: $0, traits: config.traits) } ?? config,
          drawHierarchyInKeyWindow: false,
          traits: traits,
          view: viewController.view,
          viewController: viewController
        )
      }
  }

  public static func image(
    drawHierarchyInKeyWindow: Bool = false,
    precision: Float = 1,
    size: CGSize? = nil,
    traits: UITraitCollection = .init()
    )
    -> Strategy {

      return SimpleStrategy.image(precision: precision).asyncPullback { viewController in
        snapshotView(
          config: .init(safeArea: .zero, size: size, traits: traits),
          drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
          traits: .init(),
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
#endif
