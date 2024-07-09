import XCTest

#if canImport(Testing)
  import Testing
#endif

@_spi(Internals)
public func recordIssue(
  _ message: @autoclosure () -> String,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) {
  #if canImport(Testing)
    if Test.current != nil {
      Issue.record(
        Comment(rawValue: message()),
        sourceLocation: SourceLocation(
          fileID: fileID.description,
          filePath: filePath.description,
          line: Int(line),
          column: Int(column)
        )
      )
    } else {
      XCTFail(message(), file: filePath, line: line)
    }
  #else
    XCTFail(message(), file: file, line: line)
  #endif
}
