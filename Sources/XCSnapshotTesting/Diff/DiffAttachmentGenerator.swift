import Foundation

/// Container for messages and attachments generated during snapshot comparisons.
///
/// `DiffAttachment` provides a structured way to report differences discovered during snapshot testing.
/// It encapsulates both a textual message describing what was found (for example, "2% pixel mismatch")
/// and any visual assets (such as images, diffs, or annotated screenshots) that help illustrate the
/// discrepancies. This enables richer, more actionable feedback in snapshot test results, making it
/// easier to understand and investigate test failures.
///
/// Typical uses include:
/// - Reporting pixel-level differences in image snapshots.
/// - Attaching diffed images or highlight overlays for visual comparison.
/// - Supplying serialized data (as files or text) showing the before and after state.
///
/// Attachments are platform-dependent and may be rendered or linked in test reports, depending on
/// tooling support.
///
/// Example usage:
/// ```swift
/// let attachment = DiffAttachment(
///     message: "Found color shift in bottom-right quadrant",
///     attachments: [SnapshotAttachment(image: diffImage)]
/// )
/// ```
public struct DiffAttachment: Sendable {

    /// Message describing the outcome of the snapshot comparison, summarizing key detected differences.
    ///
    /// This textual message provides actionable context for test failures, such as:
    /// - The nature or extent of detected changes (e.g., "8% pixel mismatch in bottom-right region").
    /// - Additional hints or suggestions for investigation.
    /// - Summaries of numerical, visual, or structural differences.
    ///
    /// The message should be concise yet descriptive, enabling developers to quickly understand
    /// what changed and why the test failed, even without reviewing the attached visual artifacts.
    ///
    /// Example: "Image differs: 1,304 pixels modified (3% of total)."
    public let message: String

    /// Collection of visual attachments illustrating the differences.
    ///
    /// This array contains instances of `SnapshotAttachment` that visually represent the discrepancies
    /// between the reference and test values. Typical attachments may include images highlighting
    /// regions that differ, diff overlays, annotated screenshots, or other files that provide
    /// additional context for the detected changes.
    ///
    /// Attachments support richer test reporting by enabling quick visual inspection of what
    /// changed, helping developers understand and investigate snapshot test failures more efficiently.
    ///
    /// Example: `[SnapshotAttachment(image: diffImage), SnapshotAttachment(image: croppedFailureRegion)]`
    public let attachments: [SnapshotAttachment]

    /// Initializes a new `DiffAttachment` with a descriptive message and a collection of visual attachments.
    ///
    /// - Parameters:
    ///   - message: A concise, human-readable description summarizing the key differences found during the comparison. This message should help developers quickly understand the nature or extent of the discrepancies.
    ///   - attachments: An array of `SnapshotAttachment` instances that visually represent the detected differences (such as diff images, overlays, or annotated screenshots). These attachments provide additional context to aid investigation of test failures.
    public init(message: String, attachments: [SnapshotAttachment]) {
        self.message = message
        self.attachments = attachments
    }
}

/// A protocol for generating detailed difference reports between two values during snapshot testing.
///
/// `DiffAttachmentGenerator` enables the creation of both textual summaries and visual artifacts
/// when comparing a stored reference value (e.g., a previously recorded snapshot) to a newly produced value.
/// Conformers implement logic to highlight and explain significant discrepancies, aiding in the diagnosis
/// of test failures.
///
/// Typical usages include generating:
/// - Human-readable messages summarizing differences (e.g., percentage of pixels mismatched).
/// - Visual attachments such as diff images, overlays, or annotated comparisons for richer test reports.
///
/// Implementations should return `nil` when the two values are considered equivalent within the comparison criteria,
/// ensuring attachments are only created for meaningful changes.
///
/// ## Example
/// ```swift
/// struct ImageDiffGenerator: DiffAttachmentGenerator {
///     func callAsFunction(from reference: ImageBytes, with diffable: ImageBytes) -> DiffAttachment? {
///         // Produce diff image, compare bytes, etc.
///     }
/// }
/// ```
///
/// - Note: The generator must be safe for concurrent use (`Sendable`) and should avoid blocking operations.
public protocol DiffAttachmentGenerator<Value>: Sendable {

    /// The type of values to compare during snapshot testing.
    ///
    /// `Value` represents the data being subjected to comparison by the generator. This can be any type
    /// that is `Sendable`, such as images, serialized data, or complex domain-specific structures.
    /// Conformers specify the actual type used for their comparison logic (e.g., `ImageBytes`, `UIView`, etc.).
    ///
    /// Implementations use `Value` to define the kinds of values their diffing logic handles. The generator
    /// will analyze two instances of this type—the reference (such as a previously-approved snapshot) and
    /// the new value (such as fresh test output)—and report differences via a `DiffAttachment`.
    ///
    /// - Note: `Value` must conform to `Sendable` to ensure thread-safe use during parallelized test execution.
    associatedtype Value: Sendable

    /// Compares a reference value and a newly produced value, generating a detailed difference report if discrepancies are found.
    ///
    /// Implementers should analyze the two values and, if significant differences exist, return a `DiffAttachment` that summarizes the key findings and provides visual context (such as diff images or annotated overlays). If the values are considered equivalent according to the generator's criteria (for example, pixel-for-pixel identical for image data), the function must return `nil`, indicating no actionable differences.
    ///
    /// - Parameters:
    ///   - reference: The stored reference value, typically representing an approved or baseline snapshot.
    ///   - diffable: The new value to compare against the reference, produced during the current test run.
    /// - Returns: A `DiffAttachment` encapsulating a human-readable message and any relevant visual attachments if significant differences are found, or `nil` if the values are considered equivalent.
    ///
    /// - Note: This method should be fast and thread-safe. It must not block on I/O or lengthy computations, and must be safe for concurrent use across multiple test invocations.
    func callAsFunction(
        from reference: Value,
        with diffable: Value
    ) -> DiffAttachment?
}
