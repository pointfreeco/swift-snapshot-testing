
import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

#if os(iOS) || os(tvOS)
@available(iOS 13.0, tvOS 13.0, *)
extension Snapshotting where Value: SwiftUI.View, Format == UIImage {
   
  /// A snapshot strategy for comparing SwiftUI Views based on pixel equality.
  public static var image: Snapshotting {
    return .image()
  }
    
  /// A snapshot strategy for comparing SwiftUI Views based on pixel equality.
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
      return Snapshotting<UIViewController, UIImage>
        .image(on: config,
               precision: precision,
               size: size,
               traits: traits)
        .pullback(UIHostingController.init(rootView:))
    }
    
    /// A snapshot strategy for comparing SwiftUI Views based on pixel equality.
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
      return Snapshotting<UIViewController, UIImage>
        .image(drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
               precision: precision,
               size: size,
               traits: traits)
        .pullback(UIHostingController.init(rootView:))
    }
}
#endif

