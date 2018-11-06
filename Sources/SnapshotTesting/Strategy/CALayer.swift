#if os(macOS)
import Cocoa

extension Strategy where A == CALayer, B == NSImage {
  public static var image: Strategy {
    return .image(precision: 1)
  }

  public static func image(precision: Float) -> Strategy {
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
  public static let defaultStrategy: Strategy<CALayer, NSImage> = .image
}
#elseif os(iOS) || os(tvOS)
import UIKit

extension Strategy where A == CALayer, B == UIImage {
  public static var image: Strategy {
    return .image(precision: 1)
  }

  public static func image(precision: Float) -> Strategy {
    return SimpleStrategy.image(precision: precision).pullback { layer in
      UIGraphicsImageRenderer(size: layer.bounds.size).image { context in
        layer.render(in: context.cgContext)
      }
    }
  }
}

extension CALayer: DefaultDiffable {
  public static let defaultStrategy: Strategy<CALayer, UIImage> = .image
}
#endif
