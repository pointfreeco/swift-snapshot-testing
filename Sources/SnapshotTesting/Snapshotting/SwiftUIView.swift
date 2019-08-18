
import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif


@available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
extension Snapshotting where Value: SwiftUI.View, Format == UIImage {
     
  public static var image: Snapshotting {
    return .image()
  }
        
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
