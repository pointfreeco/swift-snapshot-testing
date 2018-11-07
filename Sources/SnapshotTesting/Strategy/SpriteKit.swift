#if os(iOS) || os(macOS) || os(tvOS)
import SpriteKit
#if os(macOS)
import Cocoa
#elseif os(iOS) || os(tvOS)
import UIKit
#endif

#if os(macOS)
extension Strategy where A == SKScene, B == NSImage {
  public static func image(size: CGSize, precision: Float = 1) -> Strategy {
    return .skScene(size: size, precision: precision)
  }
}
#elseif os(iOS) || os(tvOS)
extension Strategy where A == SKScene, B == UIImage {
  public static func image(size: CGSize, precision: Float = 1) -> Strategy {
    return .skScene(size: size, precision: precision)
  }
}
#endif

fileprivate extension Strategy where A == SKScene, B == Image {
  static func skScene(size: CGSize, precision: Float) -> Strategy {
    return Strategy<View, Image>.image(precision: precision).pullback { scene in
      let view = SKView(frame: .init(x: 0, y: 0, width: size.width, height: size.height))
      view.presentScene(scene)
      return view
    }
  }
}
#endif
