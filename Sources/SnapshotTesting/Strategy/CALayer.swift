#if os(macOS)
import Cocoa

extension Strategy where A == CALayer, B == NSImage {
  public static var layer: Strategy {
    return .layer(precision: 1)
  }

  public static func layer(precision: Float) -> Strategy {
    return SimpleStrategy.image(precision: precision).pullback { layer in
      let image = NSImage(size: layer.bounds.size)
      image.lockFocus()
      let context = NSGraphicsContext.current!.cgContext
      layer.render(in: context)
      image.unlockFocus()
      return image
    }
  }
}

extension CALayer: DefaultDiffable {
  public static let defaultStrategy: Strategy<CALayer, NSImage> = .layer
}
#elseif os(iOS) || os(tvOS)
import UIKit

extension Strategy where A == CALayer, B == UIImage {
  public static var layer: Strategy {
    return .layer(precision: 1)
  }

  public static func layer(precision: Float) -> Strategy {
    return SimpleStrategy.image(precision: precision).pullback { layer in
      UIGraphicsImageRenderer(size: layer.bounds.size).image { context in
        layer.render(in: context.cgContext)
      }
    }
  }
}

extension CALayer: DefaultDiffable {
  public static let defaultStrategy: Strategy<CALayer, UIImage> = .layer
}
#endif
