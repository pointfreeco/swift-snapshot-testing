#if os(iOS) || os(tvOS)
import UIKit

extension Strategy where Snapshottable == UIViewController, Format == UIImage {
  public static var image: Strategy {
    return .image()
  }

  public static func image(
    drawingHierarchyInKeyWindow: Bool = false,
    precision: Float = 1,
    size: CGSize? = nil,
    traits: UITraitCollection = .init()
    )
    -> Strategy {

      return Strategy<UIView, UIImage>
        .image(
          drawingHierarchyInKeyWindow: drawingHierarchyInKeyWindow,
          precision: precision,
          size: size,
          traits: traits
        )
        .pullback { child in
          let size = size ?? child.view.frame.size
          let parent = traitController(for: child, size: size, traits: traits)
          return parent.view
      }
  }

  public static func image(on environment: Config, precision: Float = 1, traits: UITraitCollection = .init())
    -> Strategy {

      return .image(
        precision: precision,
        size: environment.size,
        traits: UITraitCollection(traitsFrom: [environment.traits, traits])
      )
  }
}

extension Strategy where Snapshottable == UIViewController, Format == String {
  public static var recursiveDescription: Strategy {
    return Strategy<UIView, String>.recursiveDescription.pullback { $0.view }
  }
}
#endif
