#if os(iOS) || os(macOS) || os(tvOS)
  import SpriteKit
  import ImageSerializationPlugin
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
      ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
      ///     match. 98-99% mimics
      ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
      ///     human eye.
      ///   - size: The size of the scene.
      public static func image(precision: Float = 1, perceptualPrecision: Float = 1, size: CGSize, imageFormat: ImageSerializationFormat)
        -> Snapshotting
      {
        return .skScene(precision: precision, perceptualPrecision: perceptualPrecision, size: size, imageFormat: imageFormat)
      }
    }
  #elseif os(iOS) || os(tvOS)
    extension Snapshotting where Value == SKScene, Format == UIImage {
      /// A snapshot strategy for comparing SpriteKit scenes based on pixel equality.
      ///
      /// - Parameters:
      ///   - precision: The percentage of pixels that must match.
      ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
      ///     match. 98-99% mimics
      ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
      ///     human eye.
      ///   - size: The size of the scene.
      public static func image(precision: Float = 1, perceptualPrecision: Float = 1, size: CGSize, imageFormat: ImageSerializationFormat)
        -> Snapshotting
      {
        return .skScene(precision: precision, perceptualPrecision: perceptualPrecision, size: size, imageFormat: imageFormat)
      }
    }
  #endif

  extension Snapshotting where Value == SKScene, Format == Image {
    fileprivate static func skScene(precision: Float, perceptualPrecision: Float, size: CGSize, imageFormat: ImageSerializationFormat)
      -> Snapshotting
    {
      return Snapshotting<View, Image>.image(
        precision: precision, perceptualPrecision: perceptualPrecision, imageFormat: imageFormat
      ).pullback { scene in
        let view = SKView(frame: .init(x: 0, y: 0, width: size.width, height: size.height))
        view.presentScene(scene)
        return view
      }
    }
  }
#endif
