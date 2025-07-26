#if os(macOS)
import AppKit
import Cocoa
@preconcurrency import CoreGraphics
#elseif os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#endif

#if os(macOS)
extension SyncSnapshot where Input: CGPath, Output == ImageBytes {
    /// A snapshot strategy for comparing bezier paths based on pixel equality.
    public static var image: SyncSnapshot<Input, Output> {
        .image()
    }

    /// A snapshot strategy for comparing bezier paths based on pixel equality.
    ///
    /// ``` swift
    /// // Match reference perfectly.
    /// assert(of: path, as: .image)
    ///
    /// // Allow for a 1% pixel difference.
    /// assert(of: path, as: .image(precision: 0.99))
    /// ```
    ///
    /// - Parameters:
    ///   - precision: The percentage of pixels that must match.
    ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
    ///     match. 98-99% mimics
    ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
    ///     human eye.
    ///   - drawingMode: The mode used to render the path, defined by `CGPathDrawingMode`. Determines whether the path is stroked, filled, or both.
    public static func image(
        precision: Float = 1,
        perceptualPrecision: Float = 1,
        drawingMode: CGPathDrawingMode = .eoFill
    ) -> SyncSnapshot<Input, Output> {
        IdentitySyncSnapshot.image(
            precision: precision,
            perceptualPrecision: perceptualPrecision
        ).pullback { path in
            let bounds = path.boundingBoxOfPath
            var transform = CGAffineTransform(
                translationX: -bounds.origin.x,
                y: -bounds.origin.y
            )

            let path = path.copy(using: &transform)!

            let image = NSImage(size: bounds.size, flipped: false) { destRect in
                guard let context = NSGraphicsContext.current else {
                    return false
                }

                context.imageInterpolation = .high
                context.cgContext.addPath(path)
                context.cgContext.drawPath(using: drawingMode)
                return true
            }

            return image
        }
    }
}
#elseif os(iOS) || os(tvOS) || os(visionOS)
extension SyncSnapshot where Input: CGPath, Output == ImageBytes {
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
    ///   - drawingMode: The mode used to render the path, defined by `CGPathDrawingMode`. Determines whether the path is stroked, filled, or both.
    public static func image(
        precision: Float = 1,
        perceptualPrecision: Float = 1,
        scale: CGFloat = 1,
        drawingMode: CGPathDrawingMode = .eoFill
    ) -> SyncSnapshot<Input, Output> {
        IdentitySyncSnapshot.image(
            precision: precision,
            perceptualPrecision: perceptualPrecision
        ).pullback { path in
            let bounds = path.boundingBoxOfPath
            let format: UIGraphicsImageRendererFormat
            if #available(iOS 11.0, tvOS 11.0, *) {
                format = UIGraphicsImageRendererFormat.preferred()
            } else {
                format = UIGraphicsImageRendererFormat.default()
            }
            format.scale = scale
            let renderer = UIGraphicsImageRenderer(bounds: bounds, format: format)
            return renderer.image { ctx in
                let cgContext = ctx.cgContext
                cgContext.addPath(path)
                cgContext.drawPath(using: drawingMode)
            }
        }
    }
}
#endif

#if os(macOS) || os(iOS) || os(tvOS) || os(visionOS)
extension SyncSnapshot where Input: CGPath, Output == StringBytes {
    /// A snapshot strategy for comparing bezier paths based on element descriptions.
    public static var elementsDescription: SyncSnapshot<Input, Output> {
        .elementsDescription(numberFormatter: defaultNumberFormatter)
    }

    /// A snapshot strategy for comparing bezier paths based on element descriptions.
    ///
    /// - Parameter numberFormatter: The number formatter used for formatting points.
    public static func elementsDescription(
        numberFormatter: NumberFormatter
    ) -> SyncSnapshot<
        Input, Output
    > {
        let namesByType: [CGPathElementType: String] = [
            .moveToPoint: "MoveTo",
            .addLineToPoint: "LineTo",
            .addQuadCurveToPoint: "QuadCurveTo",
            .addCurveToPoint: "CurveTo",
            .closeSubpath: "Close",
        ]

        let numberOfPointsByType: [CGPathElementType: Int] = [
            .moveToPoint: 1,
            .addLineToPoint: 1,
            .addQuadCurveToPoint: 2,
            .addCurveToPoint: 3,
            .closeSubpath: 0,
        ]

        return IdentitySyncSnapshot<StringBytes>.lines.pullback { path in
            var string: String = ""

            path.applyWithBlock { elementPointer in
                let element = elementPointer.pointee
                let name = namesByType[element.type] ?? "Unknown"

                if element.type == .moveToPoint && !string.isEmpty {
                    string += "\n"
                }

                string += name

                if let numberOfPoints = numberOfPointsByType[element.type] {
                    let points = UnsafeBufferPointer(start: element.points, count: numberOfPoints)
                    string +=
                        " "
                        + points.map { point in
                            let x = numberFormatter.string(from: point.x as NSNumber)!
                            let y = numberFormatter.string(from: point.y as NSNumber)!
                            return "(\(x), \(y))"
                        }.joined(separator: " ")
                }

                string += "\n"
            }

            return string
        }
    }
}

private let defaultNumberFormatter: NumberFormatter = {
    let numberFormatter = NumberFormatter()
    numberFormatter.decimalSeparator = "."
    numberFormatter.minimumFractionDigits = 1
    numberFormatter.maximumFractionDigits = 3
    return numberFormatter
}()
#endif
