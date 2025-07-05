#if os(macOS)
import AppKit
import Cocoa
@preconcurrency import QuartzCore

extension SyncSnapshot where Input: CALayer, Output == ImageBytes {
    /// A snapshot strategy for comparing layers based on pixel equality.
    ///
    /// ``` swift
    /// // Match reference perfectly.
    /// assert(of: layer, as: .image)
    ///
    /// // Allow for a 1% pixel difference.
    /// assert(of: layer, as: .image(precision: 0.99))
    /// ```
    public static var image: SyncSnapshot<Input, Output> {
        .image(precision: 1)
    }

    /// A snapshot strategy for comparing layers based on pixel equality.
    ///
    /// - Parameters:
    ///   - precision: The percentage of pixels that must match.
    ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
    ///     match. 98-99% mimics
    ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
    ///     human eye.
    public static func image(
        precision: Float,
        perceptualPrecision: Float = 1
    ) -> SyncSnapshot<Input, Output> {
        IdentitySyncSnapshot.image(
            precision: precision,
            perceptualPrecision: perceptualPrecision
        ).pullback { layer in
            let image = NSImage(size: layer.bounds.size)
            image.lockFocus()
            let context = NSGraphicsContext.current!.cgContext
            layer.setNeedsLayout()
            layer.layoutIfNeeded()
            layer.render(in: context)
            image.unlockFocus()
            return image
        }
    }
}
#elseif os(iOS) || os(tvOS) || os(visionOS)
import UIKit

extension SyncSnapshot where Input: CALayer, Output == ImageBytes {
    /// A snapshot strategy for comparing layers based on pixel equality.
    public static var image: SyncSnapshot<Input, Output> {
        .image()
    }

    /// A snapshot strategy for comparing layers based on pixel equality.
    ///
    /// - Parameters:
    ///   - precision: The percentage of pixels that must match.
    ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
    ///     match. 98-99% mimics
    ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
    ///     human eye.
    ///   - traits: A trait collection override.
    public static func image(
        precision: Float = 1,
        perceptualPrecision: Float = 1,
        traits: UITraitCollection = .init()
    ) -> SyncSnapshot<Input, Output> {
        IdentitySyncSnapshot.image(
            precision: precision,
            perceptualPrecision: perceptualPrecision
        ).pullback { layer in
            let renderer = UIGraphicsImageRenderer(bounds: layer.bounds, format: .init(for: traits))
            return renderer.image { ctx in
                layer.setNeedsLayout()
                layer.layoutIfNeeded()
                layer.render(in: ctx.cgContext)
            }
        }
    }
}
#endif
