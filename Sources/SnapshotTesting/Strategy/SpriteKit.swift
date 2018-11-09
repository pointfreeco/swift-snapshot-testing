#if os(iOS) || os(macOS) || os(tvOS)
import SpriteKit
#if os(macOS)
import Cocoa
#elseif os(iOS) || os(tvOS)
import UIKit
#endif

#if os(macOS)
extension Strategy where Snapshottable == SKScene, Format == NSImage {
  public static func image(precision: Float = 1, size: CGSize) -> Strategy {
    return .skScene(precision: precision, size: size)
  }
}
#elseif os(iOS) || os(tvOS)
extension Strategy where Snapshottable == SKScene, Format == UIImage {
  public static func image(precision: Float = 1, size: CGSize) -> Strategy {
    return .skScene(precision: precision, size: size)
  }
}
#endif

fileprivate extension Strategy where Snapshottable == SKScene, Format == Image {
  static func skScene(precision: Float, size: CGSize) -> Strategy {
    return Strategy<View, Image>.image(precision: precision).pullback { scene in
      let view = SKView(frame: .init(x: 0, y: 0, width: size.width, height: size.height))
      view.presentScene(scene)
      return view
    }
  }
}
#endif
