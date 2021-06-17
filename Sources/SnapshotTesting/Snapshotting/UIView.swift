#if os(iOS) || os(macOS)
import PDFKit
#endif

#if os(iOS) || os(tvOS)
import UIKit

extension Snapshotting where Value == UIView, Format == UIImage {
    /// A snapshot strategy for comparing views based on pixel equality, persisted as PNG.
    public static var image: Snapshotting {
        return .image()
    }

    /// A snapshot strategy for comparing views based on pixel equality, persisted as PNG.
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
    ) -> Snapshotting {
      return SimplySnapshotting.image(precision: precision, scale: traits.displayScale).asyncPullback { view in
          snapshotViewAsImage(
              config: .init(safeArea: .zero, size: size ?? view.frame.size, traits: .init()),
              drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
              traits: traits,
              view: view,
              viewController: .init()
          )
      }
    }
}
#endif

#if os(iOS)
@available(iOS 11.0, macOS 10.4, *)
extension Snapshotting where Value == UIView, Format == PDFDocument {
  /// A snapshot strategy for comparing views based on pixel equality, persisted as PDF.
  @available(iOS 11.0, macOS 10.4, *)
  public static var pdf: Snapshotting {
    return .pdf()
  }

  /// A snapshot strategy for comparing views based on pixel equality, persisted as PDF.
  ///
  /// - Parameters:
  ///   - drawHierarchyInKeyWindow: Utilize the simulator's key window in order to render `UIAppearance` and `UIVisualEffect`s. This option requires a host application for your tests and will _not_ work for framework test targets.
  ///   - precision: The percentage of pixels that must match.
  ///   - size: A view size override.
  ///   - traits: A trait collection override.
  @available(iOS 11.0, macOS 10.4, *)
  public static func pdf(
    drawHierarchyInKeyWindow: Bool = false,
    precision: Float = 1,
    size: CGSize? = nil,
    traits: UITraitCollection = .init()
    )
    -> Snapshotting {

      return SimplySnapshotting.rasterized(precision: precision).asyncPullback { view in
        snapshotViewAsPDF(
        config: .init(safeArea: .zero, size: size ?? view.frame.size, traits: traits),
        drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
        traits: traits,
        view: view,
        viewController: .init()
      )
    }
  }
}
#endif

#if os(iOS) || os(tvOS)
extension Snapshotting where Value == UIView, Format == String {
  /// A snapshot strategy for comparing views based on a recursive description of their properties and hierarchies.
  public static var recursiveDescription: Snapshotting {
    return Snapshotting.recursiveDescription()
  }

  /// A snapshot strategy for comparing views based on a recursive description of their properties and hierarchies.
  public static func recursiveDescription(
    size: CGSize? = nil,
    traits: UITraitCollection = .init()
  ) -> Snapshotting<UIView, String> {
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
