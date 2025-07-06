#if os(iOS) || os(tvOS) || os(visionOS)
@preconcurrency import UIKit

extension SyncSnapshot where Input: UIBezierPath, Output == ImageBytes {
    /// A snapshot strategy for comparing bezier paths based on pixel equality.
    public static var image: SyncSnapshot<Input, Output> {
        .image()
    }

    /// A snapshot strategy for comparing bezier paths based on pixel equality.
    ///
    /// - Parameters:
    ///   - precision: The percentage of pixels that must match.
    ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
    ///     match. 98-99% mimics
    ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
    ///     human eye.
    ///   - scale: The scale factor for the rendered image.
    public static func image(
        precision: Float = 1,
        perceptualPrecision: Float = 1,
        scale: CGFloat = 1
    ) -> SyncSnapshot<Input, Output> {
        IdentitySyncSnapshot.image(
            precision: precision,
            perceptualPrecision: perceptualPrecision
        ).pullback { path in
            let bounds = path.bounds
            let format: UIGraphicsImageRendererFormat
            if #available(iOS 11.0, tvOS 11.0, *) {
                format = UIGraphicsImageRendererFormat.preferred()
            } else {
                format = UIGraphicsImageRendererFormat.default()
            }
            format.scale = scale
            let renderer = UIGraphicsImageRenderer(bounds: bounds, format: format)
            return renderer.image { ctx in
                path.fill()
            }
        }
    }
}

extension SyncSnapshot where Input: UIBezierPath, Output == StringBytes {
    /// A snapshot strategy for comparing bezier paths based on pixel equality.
    public static var elementsDescription: SyncSnapshot<Input, Output> {
        SyncSnapshot<CGPath, StringBytes>.elementsDescription.pullback {
            $0.cgPath
        }
    }

    /// A snapshot strategy for comparing bezier paths based on pixel equality.
    ///
    /// - Parameter numberFormatter: The number formatter used for formatting points.
    public static func elementsDescription(
        numberFormatter: NumberFormatter
    ) -> SyncSnapshot<
        Input, Output
    > {
        SyncSnapshot<CGPath, StringBytes>.elementsDescription(
            numberFormatter: numberFormatter
        ).pullback { path in path.cgPath }
    }
}
#endif
