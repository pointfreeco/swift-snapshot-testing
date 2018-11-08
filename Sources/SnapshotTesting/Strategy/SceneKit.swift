#if os(iOS) || os(macOS) || os(tvOS)
import SceneKit
#if os(macOS)
import Cocoa
#elseif os(iOS) || os(tvOS)
import UIKit
#endif

#if os(macOS)
extension Strategy where Snapshottable == SCNScene, Format == NSImage {
  public static func image(precision: Float = 1, size: CGSize) -> Strategy {
    return .scnScene(precision: precision, size: size)
  }
}
#elseif os(iOS) || os(tvOS)
extension Strategy where Snapshottable == SCNScene, Format == UIImage {
  public static func image(precision: Float = 1, size: CGSize) -> Strategy {
    return .scnScene(precision: precision, size: size)
  }
}
#endif

fileprivate extension Strategy where Snapshottable == SCNScene, Format == Image {
  static func scnScene(precision: Float, size: CGSize) -> Strategy {
    return Strategy<View, Image>.image(precision: precision).pullback { scene in
      let view = SCNView(frame: .init(x: 0, y: 0, width: size.width, height: size.height))
      view.scene = scene
      return view
    }
  }
}
#endif
