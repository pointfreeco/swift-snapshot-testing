import Foundation
@preconcurrency import XCTest

/// Container for messages and attachments generated during snapshot comparisons.
///
/// `DiffAttachment` stores a textual description of differences between two values (like images
/// or serialized data) along with visual attachments (e.g., comparison images), making it easier to identify
/// visual discrepancies.
public struct DiffAttachment: Sendable {

  /// Message describing the detected differences.
  ///
  /// Example: "5% pixel difference in the central region of the image".
  public let message: String

  /// Collection of visual attachments illustrating the differences.
  ///
  /// May include images highlighting divergent regions or graphical diffs.
  public let attachments: [XCTAttachment]

  /// Initializes a `DiffAttachment` with message and attachments.
  ///
  /// - Parameters:
  ///   - message: Textual description of the difference.
  ///   - attachments: Visual attachments complementing the message.
  public init(message: String, attachments: [XCTAttachment]) {
    self.message = message
    self.attachments = attachments
  }
}

/// Protocol to generate comparison (diff) attachments between values during snapshot tests.
///
/// Types conforming to `DiffAttachmentGenerator` must implement generation of textual messages
/// and visual attachments (e.g., images) showing differences between reference and test values.
/// Provides detailed feedback when a snapshot doesn't match the stored version.
public protocol DiffAttachmentGenerator<Value>: Sendable {

  /// Type of values to compare (e.g., `ImageBytes`).
  associatedtype Value: Sendable

  /// Generates a textual description and attachments highlighting differences between values.
  ///
  /// - Parameters:
  ///   - reference: Reference value (original snapshot).
  ///   - diffable: Value to compare (new snapshot version).
  /// - Returns: `DiffAttachment?`: Tuple with message and attachments if significant differences exist.
  ///
  /// - WARNING: Returns `nil` if values are considered identical within comparison criteria.
  func callAsFunction(
    from reference: Value,
    with diffable: Value
  ) -> DiffAttachment?
}
