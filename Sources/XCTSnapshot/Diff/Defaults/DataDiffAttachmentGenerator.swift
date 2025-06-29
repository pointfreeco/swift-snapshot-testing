import Foundation

/// A diff attachment generator that compares two data blobs (typically images or binary snapshots) and generates an attachment describing any differences.
///
/// `DataDiffAttachmentGenerator` is designed for use in snapshot or data comparison tests. When invoked, it compares the raw values of two `DataBytes` inputs (such as reference and generated images).
///
/// If the data do not match, it returns a `DiffAttachment` containing a message indicating the mismatch. If the data are identical, it returns `nil`.
///
/// This type is intended for use with snapshot testing frameworks and utilities that display or log detailed differences between binary artifacts such as images.
///
/// Usage:
/// ```swift
/// let diff = DataDiffAttachmentGenerator()
/// let result = diff(from: referenceData, with: newData)
/// // Use `result` to inspect or report differences.
/// ```
///
/// - Note: This implementation does not attempt to visualize binary differences; it only reports on mismatches and provides a simple message.
/// - SeeAlso: `DiffAttachment`, `DiffAttachmentGenerator`
public struct DataDiffAttachmentGenerator: DiffAttachmentGenerator {

    public init() {}

    /// Compares two data blobs and generates a diff attachment describing any differences.
    ///
    /// - Parameters:
    ///   - reference: The reference data against which to compare (typically the baseline or "golden" data).
    ///   - diffable: The data to compare against the reference (typically the newly generated data).
    /// - Returns: A `DiffAttachment` containing a message describing the difference if the data do not match, or `nil` if the data are identical.
    ///
    /// This method is intended for snapshot or binary comparison testing, where two data blobs—such as images or other binary artifacts—need to be compared for equality.
    /// When the data differ, the returned `DiffAttachment` includes a brief message describing the mismatch.
    /// No visual diff or binary details are attached; the result is meant for simple reporting of mismatches.
    public func callAsFunction(
        from reference: DataBytes,
        with diffable: DataBytes
    ) -> DiffAttachment? {
        guard reference.rawValue != diffable.rawValue else {
            return nil
        }

        let message =
            reference.rawValue.count == diffable.rawValue.count
            ? "Expected data to match"
            : "Expected \(diffable.rawValue) to match \(reference.rawValue)"

        return DiffAttachment(
            message: message,
            attachments: []
        )
    }
}

extension DiffAttachmentGenerator where Self == DataDiffAttachmentGenerator {

    /// A convenience static property for accessing the standard data diff attachment generator.
    ///
    /// Use this property to obtain a `DataDiffAttachmentGenerator`, which compares two data blobs (such as images or binary files) and generates a diff attachment if they do not match.
    ///
    /// Example usage:
    /// ```swift
    /// let generator = DiffAttachmentGenerator.data
    /// let diff = generator(from: referenceData, with: newData)
    /// ```
    ///
    /// - Returns: A `DataDiffAttachmentGenerator` instance for performing data comparisons in tests.
    public static var data: Self {
        DataDiffAttachmentGenerator()
    }
}
