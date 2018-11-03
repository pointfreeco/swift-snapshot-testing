#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
import SpriteKit
#if os(macOS)
import Cocoa
#elseif os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#endif

#if os(macOS)
extension Strategy where A == SKScene, B == NSImage {
  public static func scene(size: CGSize) -> Strategy {
    return .skScene(size: size)
  }
}
#elseif os(iOS) || os(tvOS) || os(watchOS)
extension Strategy where A == SKScene, B == UIImage {
  public static func scene(size: CGSize) -> Strategy {
    return .skScene(size: size)
  }
}
#endif

fileprivate extension Strategy where A == SKScene, B == Image {
  static func skScene(size: CGSize) -> Strategy {
    return Strategy<View, Image>.view.pullback { scene in
      let view = SKView(frame: .init(x: 0, y: 0, width: size.width, height: size.height))
      view.presentScene(scene)
      return view
    }
  }
}
#endif
