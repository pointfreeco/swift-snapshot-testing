import XCTest

#if canImport(Testing)
  import Testing
#endif

@_spi(Internals)
public func recordIssue(
  _ message: @autoclosure () -> String,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  #if canImport(Testing)
    if Test.current != nil {
      Issue.record(
        Comment(rawValue: message()),
        filePath: file.description,
        line: Int(line)
      )
    } else {
      XCTFail(message(), file: file, line: line)
    }
  #else
    XCTFail(message(), file: file, line: line)
  #endif
}
