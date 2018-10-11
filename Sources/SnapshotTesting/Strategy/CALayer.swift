#if os(macOS)
import Cocoa

extension Strategy {
  public static var layer: Strategy<CALayer, NSImage> {
    return Strategy.image.pre { layer in
      let image = NSImage(size: layer.bounds.size)
      image.lockFocus()
      guard let context = NSGraphicsContext.current?.cgContext else { return nil }
      layer.render(in: context)
      image.unlockFocus()
      return image
    }
  }
}

extension CALayer: DefaultDiffable {
  public static let defaultStrategy: Strategy<CALayer, NSImage> = .layer
}
#elseif os(iOS) || os(tvOS) || os(watchOS)
import UIKit

extension Strategy {
  public static var layer: Strategy<CALayer, UIImage> {
    return Strategy.image.pre { layer in
      UIGraphicsBeginImageContextWithOptions(layer.bounds.size, false, 2.0)
      defer { UIGraphicsEndImageContext() }
      guard let context = UIGraphicsGetCurrentContext() else { return nil }
      layer.render(in: context)
      return UIGraphicsGetImageFromCurrentImageContext()
    }
  }
}

extension CALayer: DefaultDiffable {
  public static let defaultStrategy: Strategy<CALayer, UIImage> = .layer
}
#endif
