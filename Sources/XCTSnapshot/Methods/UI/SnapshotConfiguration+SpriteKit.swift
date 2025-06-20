#if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
import SpriteKit
#if os(macOS)
import Cocoa
#elseif os(iOS) || os(tvOS)
import UIKit
#endif

#if os(macOS)
extension AsyncSnapshot where Input: SKScene & Sendable, Output == ImageBytes {
  /// A snapshot strategy for comparing SpriteKit scenes based on pixel equality.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
  ///     match. 98-99% mimics
  ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
  ///     human eye.
  ///   - size: The size of the scene.
  public static func image(
    drawHierarchyInKeyWindow: Bool = false,
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    size: CGSize,
    delay: Double = .zero,
    application: NSApplication? = nil
  ) -> AsyncSnapshot<Input, Output> {
    .skScene(
      drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
      precision: precision,
      perceptualPrecision: perceptualPrecision,
      size: size,
      delay: delay,
      application: application
    )
  }
}
#elseif os(iOS) || os(tvOS) || os(visionOS)
extension AsyncSnapshot where Input: SKScene, Output == ImageBytes {
  /// A snapshot strategy for comparing SpriteKit scenes based on pixel equality.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
  ///     match. 98-99% mimics
  ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
  ///     human eye.
  ///   - size: The size of the scene.
  public static func image(
    drawHierarchyInKeyWindow: Bool = false,
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    size: CGSize,
    delay: Double = .zero,
    application: UIKit.UIApplication? = nil
  ) -> AsyncSnapshot<Input, Output> {
    .skScene(
      drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
      precision: precision,
      perceptualPrecision: perceptualPrecision,
      size: size,
      delay: delay,
      application: application
    )
  }
}
#endif

extension AsyncSnapshot where Input: SKScene, Output == ImageBytes {

  fileprivate static func skScene(
    drawHierarchyInKeyWindow: Bool,
    precision: Float,
    perceptualPrecision: Float,
    size: CGSize,
    delay: Double,
    application: SDKApplication?
  ) -> AsyncSnapshot<Input, Output> {
    AsyncSnapshot<SDKView, ImageBytes>.image(
      drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
      precision: precision,
      perceptualPrecision: perceptualPrecision,
      layout: .fixed(width: size.width, height: size.height),
      delay: delay,
      application: application
    ).pullback { @MainActor scene in
      let view = SKView(frame: .init(origin: .zero, size: size))
      view.presentScene(scene)
      return view
    }
  }
}
#endif
