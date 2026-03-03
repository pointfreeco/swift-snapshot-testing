import Foundation

#if !os(Linux) && !os(Android) && !os(Windows) && canImport(XCTest)
  import XCTest
#endif

#if canImport(Testing) && compiler(>=6.2)
  import Testing
#endif

/// Helper for Swift Testing attachment recording.
///
/// Records attachments asynchronously for better performance with large test suites.
internal enum STAttachments {
  #if canImport(Testing) && compiler(>=6.2)
    static func record(
      _ data: Data,
      named name: String? = nil,
      fileID: StaticString,
      filePath: StaticString,
      line: UInt,
      column: UInt
    ) {
      guard Test.current != nil else { return }

      // Record asynchronously to avoid blocking test execution.
      // Using Task (not .detached) ensures Test.current context is inherited.
      Task {
        Attachment.record(
          data,
          named: name,
          sourceLocation: SourceLocation(
            fileID: fileID.description,
            filePath: filePath.description,
            line: Int(line),
            column: Int(column)
          )
        )
      }
    }
  #else
    static func record(
      _ data: Data,
      named name: String? = nil,
      fileID: StaticString,
      filePath: StaticString,
      line: UInt,
      column: UInt
    ) {
    }
  #endif
}
