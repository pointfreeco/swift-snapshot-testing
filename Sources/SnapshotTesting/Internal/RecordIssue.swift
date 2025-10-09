import XCTest

#if canImport(Testing)
  import Testing
#endif

var isSwiftTesting: Bool {
  #if canImport(Testing)
    return Test.current != nil
  #else
    return false
  #endif
}

@_spi(Internals)
public func recordIssue(
  _ message: @autoclosure () -> String,
  fileID: StaticString,
  filePath: StaticString,
  line: UInt,
  column: UInt
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
    XCTFail(message(), file: filePath, line: line)
  #endif
}
