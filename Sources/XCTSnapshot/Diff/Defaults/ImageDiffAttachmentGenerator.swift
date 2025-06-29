#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(macOS)
@preconcurrency import AppKit
#endif

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS) || os(visionOS)
/// `ImageDiffAttachmentGenerator` is a utility for visual snapshot testing that highlights and reports
/// differences between two images, usually representing the expected (reference) and actual (diffable) output
/// from a UI or graphics test.
///
/// This generator compares images at the pixel level and, if differences are detected beyond the specified
/// thresholds, produces both textual descriptions of the differences and attachments that visualize them
/// (such as a difference image and annotated copies of the input images).
///
/// - Parameters:
///   - precision: The strictness of the pixel-wise comparison. A value of `1.0` requires identical pixels,
///                while lower values allow for small variations.
///   - perceptualPrecision: The threshold for color difference when comparing images perceptually. This allows
///                for tolerant or "fuzzy" comparisons that are less strict about exact color matching, useful
///                when minor rendering differences are acceptable.
///
/// On difference detection, the generator outputs a `DiffAttachment` which includes:
///   - A message describing the type and severity of the difference.
///   - Attachments: Visual representations of the reference image, the diffable image (or a placeholder if empty),
///     and a difference image highlighting discrepancies.
///
/// This type is commonly used in snapshot and UI regression testing suites to make visual regressions
/// easy to spot and diagnose during continuous integration or local development.
public struct ImageDiffAttachmentGenerator: DiffAttachmentGenerator {

    private let precision: Float
    private let perceptualPrecision: Float

    /// Initializes a new `ImageDiffAttachmentGenerator` with the specified comparison thresholds.
    ///
    /// - Parameters:
    ///   - precision: The pixel-wise comparison threshold. A value of `1.0` requires exact pixel matches,
    ///                while lower values allow minor variations, making the comparison less strict.
    ///   - perceptualPrecision: The color difference threshold for perceptual (fuzzy) image comparisons.
    ///                Lower values make the comparison more tolerant of small color variations, which
    ///                is useful for ignoring minor rendering differences that are not visually significant.
    ///
    /// Use this initializer to specify how strict or lenient the image difference detection should be,
    /// enabling customized snapshot test sensitivity.
    public init(
        precision: Float,
        perceptualPrecision: Float
    ) {
        self.precision = precision
        self.perceptualPrecision = perceptualPrecision
    }

    /// Compares two images and generates a `DiffAttachment` if significant visual differences are detected.
    ///
    /// This function performs a pixel-wise and perceptual comparison between a reference image and a diffable (test) image.
    /// If the differences between the two images exceed the configured `precision` or `perceptualPrecision` thresholds,
    /// the function produces a descriptive message and attachments, including:
    ///   - The original reference image.
    ///   - The diffable (test) image or, if it is empty, a placeholder.
    ///   - A difference image that highlights detected discrepancies.
    ///
    /// Use this function in visual regression or snapshot testing to identify and visualize unintended UI changes.
    ///
    /// - Parameters:
    ///   - reference: The known-correct (reference) image to compare against.
    ///   - diffable: The image under test, to be compared to the reference.
    /// - Returns: A `DiffAttachment` containing a textual difference summary and visual attachments if a significant
    ///            difference is found; otherwise, returns `nil` if the images are considered equivalent.
    public func callAsFunction(
        from reference: ImageBytes,
        with diffable: ImageBytes
    ) -> DiffAttachment? {
        performOnMainThread {
            guard
                let message = reference.rawValue.compare(
                    diffable.rawValue,
                    precision: precision,
                    perceptualPrecision: perceptualPrecision
                )
            else { return nil }

            let difference = reference.rawValue.substract(diffable.rawValue)
            var oldAttachment = SnapshotAttachment(image: reference.rawValue)
            oldAttachment?.name = "reference"
            let isEmptyImage = diffable.rawValue.size == .zero
            var newAttachment = SnapshotAttachment(
                image: isEmptyImage ? SDKImage.empty : diffable.rawValue
            )
            newAttachment?.name = "failure"
            var differenceAttachment = SnapshotAttachment(image: difference)
            differenceAttachment?.name = "difference"

            return DiffAttachment(
                message: message,
                attachments: [oldAttachment, newAttachment, differenceAttachment].compactMap(\.self)
            )
        }
    }
}
#endif
