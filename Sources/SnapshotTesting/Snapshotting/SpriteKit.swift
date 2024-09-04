#if os(iOS) || os(macOS) || os(tvOS)
import SpriteKit
#if os(macOS)
import Cocoa
#elseif os(iOS) || os(tvOS)
import UIKit
#endif

#if os(macOS)
extension Snapshotting where Value == SKScene, Format == NSImage {
  /// A snapshot strategy for comparing SpriteKit scenes based on pixel equality.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - size: The size of the scene.
  public static func image(precision: Float = 1, size: CGSize, format: ImageFormat) -> Snapshotting {
    return .skScene(precision: precision, size: size, format: format)
  }
}
#elseif os(iOS) || os(tvOS)
extension Snapshotting where Value == SKScene, Format == UIImage {
  /// A snapshot strategy for comparing SpriteKit scenes based on pixel equality.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - size: The size of the scene.
  public static func image(precision: Float = 1, size: CGSize, format: ImageFormat) -> Snapshotting {
    return .skScene(precision: precision, size: size, format: format)
  }
}
#endif

fileprivate extension Snapshotting where Value == SKScene, Format == Image {
  static func skScene(precision: Float, size: CGSize, format: ImageFormat) -> Snapshotting {
    return Snapshotting<View, Image>.image(precision: precision, format: format).pullback { scene in
      let view = SKView(frame: .init(x: 0, y: 0, width: size.width, height: size.height))
      view.presentScene(scene)
      return view
    }
  }
}
#endif
