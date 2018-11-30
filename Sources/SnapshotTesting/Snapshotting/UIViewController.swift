#if os(iOS) || os(tvOS)
import UIKit

extension Snapshotting where Value == UIViewController, Format == UIImage {
  /// A snapshot strategy for comparing view controller views based on pixel equality.
  public static var image: Snapshotting {
    return .image()
  }

  /// A snapshot strategy for comparing view controller views based on pixel equality.
  ///
  /// - Parameters:
  ///   - config: A set of device configuration settings.
  ///   - precision: The percentage of pixels that must match.
  ///   - size: A view size override.
  ///   - traits: A trait collection override.
  public static func image(
    on config: ViewImageConfig,
    precision: Float = 1,
    size: CGSize? = nil,
    traits: UITraitCollection = .init()
    )
    -> Snapshotting {

      return SimplySnapshotting.image(precision: precision).asyncPullback { viewController in
        snapshotView(
          config: size.map { .init(safeArea: config.safeArea, size: $0, traits: config.traits) } ?? config,
          drawHierarchyInKeyWindow: false,
          traits: traits,
          view: viewController.view,
          viewController: viewController
        )
      }
  }

  /// A snapshot strategy for comparing view controller views based on pixel equality.
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
    -> Snapshotting {

      return SimplySnapshotting.image(precision: precision).asyncPullback { viewController in
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

extension Snapshotting where Value == UIViewController, Format == String {
  /// A snapshot strategy for comparing view controller views based on a recursive description of their properties and hierarchies.
  public static var recursiveDescription: Snapshotting {
    return Snapshotting<UIView, String>.recursiveDescription.pullback { $0.view }
  }
}
#endif
