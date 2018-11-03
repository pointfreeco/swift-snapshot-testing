#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
import SceneKit
#if os(macOS)
import Cocoa
#elseif os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#endif

#if os(macOS)
extension Strategy where A == SCNScene, B == NSImage {
  public static func scene(size: CGSize) -> Strategy {
    return .scnScene(size: size)
  }
}
#elseif os(iOS) || os(tvOS) || os(watchOS)
extension Strategy where A == SCNScene, B == UIImage {
  public static func scene(size: CGSize) -> Strategy {
    return .scnScene(size: size)
  }
}
#endif

fileprivate extension Strategy where A == SCNScene, B == Image {
  static func scnScene(size: CGSize) -> Strategy {
    return Strategy<View, Image>.view.pullback { scene in
      let view = SCNView(frame: .init(x: 0, y: 0, width: size.width, height: size.height))
      view.scene = scene
      return view
    }
  }
}
#endif
