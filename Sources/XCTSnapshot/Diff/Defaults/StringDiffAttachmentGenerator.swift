import Foundation
import XCTest

public struct StringDiffAttachmentGenerator: DiffAttachmentGenerator {

  public init() {}

  public func callAsFunction(
    from reference: StringBytes,
    with diffable: StringBytes
  ) -> DiffAttachment? {
    guard reference.rawValue != diffable.rawValue else {
      return nil
    }

    let hunks = reference.rawValue
      .split(separator: "\n", omittingEmptySubsequences: false)
      .map(String.init)
      .diffing(
        diffable.rawValue
          .split(separator: "\n", omittingEmptySubsequences: false)
          .map(String.init)
      )
      .groupping()

    let failure =
      hunks
      .flatMap { [$0.patchMarker] + $0.lines }
      .joined(separator: "\n")

    let attachment = XCTAttachment(
      data: Data(failure.utf8),
      uniformTypeIdentifier: "public.patch-file"
    )

    return DiffAttachment(
      message: failure,
      attachments: [attachment]
    )
  }
}

extension DiffAttachmentGenerator where Self == StringDiffAttachmentGenerator {
  /// A line-diffing strategy for UTF-8 text.
  public static var lines: Self {
    StringDiffAttachmentGenerator()
  }
}
