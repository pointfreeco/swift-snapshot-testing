#if os(iOS) || os(tvOS)
import UIKit

extension Strategy where Snapshottable == UIView, Format == UIImage {
  /// A snapshot strategy for comparing views based on pixel equality.
  public static var image: Strategy {
    return .image()
  }

  /// A snapshot strategy for comparing views based on pixel equality.
  ///
  /// - Parameters:
  ///   - drawHierarchyInKeyWindow: Utilize the simulator's key window in order to render `UIAppearance` and `UIVisualEffect`s. This option requires a host application for your tests and will _not_ work for framework test targets.
  ///   - precision: The percentage of pixels that must match.
  ///   - size: A view size override.
  ///   - traits: A trait collection override.
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
  /// A snapshot strategy for comparing views based on a recursive description of their properties and hierarchies.
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
