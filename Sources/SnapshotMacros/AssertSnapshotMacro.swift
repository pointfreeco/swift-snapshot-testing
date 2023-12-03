
import Foundation
import SnapshotTesting

@freestanding(expression)
public macro AssertSnapshotEqual<Value, Format>(
    of value: @autoclosure () throws -> Value,
    as snapshotting: Snapshotting<Value, Format>,
    named name: String? = nil,
    record recording: Bool = false,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
  ) = #externalMacro(module: "SnapshotTestingMacros", type: "AssertSnapshotEqualMacro")
