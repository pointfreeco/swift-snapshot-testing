#if os(iOS) || os(tvOS)
import UIKit

extension Snapshotting where Value == UIView, Format == UIImage {
  /// A snapshot strategy for comparing views based on pixel equality.
  public static var image: Snapshotting {
    return .image()
  }

  /// A snapshot strategy for comparing views based on pixel equality.
  ///
  /// - Parameters:
  ///   - drawHierarchyInKeyWindow: Utilize the simulator's key window in order to render `UIAppearance` and `UIVisualEffect`s. This option requires a host application for your tests and will _not_ work for framework test targets.
  ///   - precision: The percentage of pixels that must match.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match. [98-99% mimics the precision of the human eye.](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e)
  ///   - size: A view size override.
  ///   - traits: A trait collection override.
  public static func image(
    drawHierarchyInKeyWindow: Bool = false,
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    size: CGSize? = nil,
    traits: UITraitCollection = .init()
    )
    -> Snapshotting {

      return SimplySnapshotting.image(precision: precision, perceptualPrecision: perceptualPrecision, scale: traits.displayScale).asyncPullback { view in
        snapshotView(
          config: .init(safeArea: .zero, size: size ?? view.frame.size, traits: .init()),
          drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
          traits: traits,
          view: view,
          viewController: .init()
        )
      }
  }
  
  /// A snapshot strategy for comparing views based on pixel equality.
  ///
  /// - Parameters:
  ///   - config: A set of device configuration settings.
  ///   - precision: The percentage of pixels that must match.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match. [98-99% mimics the precision of the human eye.](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e)
  ///   - targetSize: The size that you prefer for the view. To obtain a view that is as small as possible, specify the constant [layoutFittingCompressedSize](https://developer.apple.com/documentation/uikit/uiview/1622568-layoutfittingcompressedsize). To obtain a view that is as large as possible, specify the constant [layoutFittingExpandedSize](https://developer.apple.com/documentation/uikit/uiview/1622532-layoutfittingexpandedsize).
  ///   - horizontalFittingPriority: The priority for horizontal constraints. Specify [fittingSizeLevel](https://developer.apple.com/documentation/uikit/uilayoutpriority/1622248-fittingsizelevel) to get a width that is as close as possible to the width value of `targetSize`.
  ///   - verticalFittingPriority: The priority for vertical constraints. Specify [fittingSizeLevel](https://developer.apple.com/documentation/uikit/uilayoutpriority/1622248-fittingsizelevel) to get a height that is as close as possible to the height value of `targetSize`.
  ///   - traits: A trait collection override.
  public static func image(
    drawHierarchyInKeyWindow: Bool = false,
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    targetSize: CGSize,
    horizontalFittingPriority: UILayoutPriority,
    verticalFittingPriority: UILayoutPriority,
    traits: UITraitCollection = .init()
    )
    -> Snapshotting {

      return SimplySnapshotting.image(precision: precision, perceptualPrecision: perceptualPrecision, scale: traits.displayScale).asyncPullback { view in
        let size = view.systemLayoutSizeFitting(
          targetSize,
          withHorizontalFittingPriority: horizontalFittingPriority,
          verticalFittingPriority: verticalFittingPriority
        )
        return snapshotView(
          config: .init(safeArea: .zero, size: size, traits: .init()),
          drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
          traits: traits,
          view: view,
          viewController: .init()
        )
      }
  }
}

extension Snapshotting where Value == UIView, Format == String {
  /// A snapshot strategy for comparing views based on a recursive description of their properties and hierarchies.
  public static var recursiveDescription: Snapshotting {
    return Snapshotting.recursiveDescription()
  }

  /// A snapshot strategy for comparing views based on a recursive description of their properties and hierarchies.
  public static func recursiveDescription(
    size: CGSize? = nil,
    traits: UITraitCollection = .init()
    )
    -> Snapshotting<UIView, String> {
      return SimplySnapshotting.lines.pullback { view in
        let dispose = prepareView(
          config: .init(safeArea: .zero, size: size ?? view.frame.size, traits: traits),
          drawHierarchyInKeyWindow: false,
          traits: .init(),
          view: view,
          viewController: .init()
        )
        defer { dispose() }
        return purgePointers(
          view.perform(Selector(("recursiveDescription"))).retain().takeUnretainedValue()
            as! String
        )
      }
  }
}
#endif
