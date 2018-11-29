#if os(iOS) || os(tvOS)
import UIKit

extension Strategy where Snapshottable == UIView, Format == UIImage {
  public static var image: Strategy {
    return .image()
  }

  public static func image(
    drawHierarchyInKeyWindow: Bool = false,
    precision: Float = 1,
    size: CGSize? = nil,
    traits: UITraitCollection = .init()
    )
    -> Strategy {

      return SimpleStrategy.image(precision: precision).asyncPullback { view in
        snapshotView(
          config: .init(safeArea: .zero, size: size ?? view.frame.size, traits: .init()),
          drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
          traits: traits,
          view: view,
          viewController: .init()
        )
      }
  }
}

extension Strategy where Snapshottable == UIView, Format == String {
  public static var recursiveDescription: Strategy<UIView, String> {
    return SimpleStrategy.lines.pullback { view in
      view.setNeedsLayout()
      view.layoutIfNeeded()
      return purgePointers(
        view.perform(Selector(("recursiveDescription"))).retain().takeUnretainedValue()
          as! String
      )
    }
  }
}
#endif
