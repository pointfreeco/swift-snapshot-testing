import Foundation
import XCTest

public struct DataDiffAttachmentGenerator: DiffAttachmentGenerator {

  public init() {}

  /// Compares two images and generates a descriptive message or visual attachments highlighting differences.
  ///
  /// - Parameter reference: Reference image (original snapshot).
  /// - Parameter diffable: Image to compare (new snapshot version).
  /// - Returns: `DiffAttachment` containing a descriptive message and visual attachments if significant differences exist.
  public func callAsFunction(
    from reference: DataBytes,
    with diffable: DataBytes
  ) -> DiffAttachment? {
    guard reference.rawValue != diffable.rawValue else {
      return nil
    }

    let message = reference.rawValue.count == diffable.rawValue.count
      ? "Expected data to match"
      : "Expected \(diffable.rawValue) to match \(reference.rawValue)"

    return DiffAttachment(
      message: message,
      attachments: []
    )
  }
}

extension DiffAttachmentGenerator where Self == DataDiffAttachmentGenerator {

  public static var data: Self {
    DataDiffAttachmentGenerator()
  }
}
