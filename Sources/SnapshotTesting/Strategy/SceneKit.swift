#if os(iOS) || os(macOS) || os(tvOS)
import SceneKit
#if os(macOS)
import Cocoa
#elseif os(iOS) || os(tvOS)
import UIKit
#endif

#if os(macOS)
extension Strategy where A == SCNScene, B == NSImage {
  public static func scene(size: CGSize, precision: Float = 1) -> Strategy {
    return .scnScene(size: size, precision: precision)
  }
}
#elseif os(iOS) || os(tvOS)
extension Strategy where A == SCNScene, B == UIImage {
  public static func scene(size: CGSize, precision: Float = 1) -> Strategy {
    return .scnScene(size: size, precision: precision)
  }
}
#endif

fileprivate extension Strategy where A == SCNScene, B == Image {
  static func scnScene(size: CGSize, precision: Float) -> Strategy {
    return Strategy<View, Image>.view(precision: precision).pullback { scene in
      let view = SCNView(frame: .init(x: 0, y: 0, width: size.width, height: size.height))
      view.scene = scene
      return view
    }
  }
}
#endif
