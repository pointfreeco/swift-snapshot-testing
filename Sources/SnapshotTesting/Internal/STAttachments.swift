import Foundation

#if !os(Linux) && !os(Android) && !os(Windows) && canImport(XCTest)
  import XCTest
#endif

#if canImport(Testing) && compiler(>=6.2)
  import Testing
#endif

/// Helper for Swift Testing attachment recording
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
