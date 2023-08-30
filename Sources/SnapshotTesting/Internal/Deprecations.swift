import Foundation
import XCTest

@available(iOS, deprecated: 10000, message: "Use `assertSnapshot(of:…:)` instead.")
@available(macOS, deprecated: 10000, message: "Use `assertSnapshot(of:…:)` instead.")
@available(tvOS, deprecated: 10000, message: "Use `assertSnapshot(of:…:)` instead.")
@available(watchOS, deprecated: 10000, message: "Use `assertSnapshot(of:…:)` instead.")
public func assertSnapshot<Value, Format>(
  matching value: @autoclosure () throws -> Value,
  as snapshotting: Snapshotting<Value, Format>,
  named name: String? = nil,
  record recording: Bool = false,
  timeout: TimeInterval = 5,
  file: StaticString = #file,
  testName: String = #function,
  line: UInt = #line
) {
  assertSnapshot(
    of: try value(),
    as: snapshotting,
    named: name,
    record: recording,
    timeout: timeout,
    file: file,
    testName: testName,
    line: line
  )
}

@available(iOS, deprecated: 10000, message: "Use `assertSnapshots(of:…:)` instead.")
@available(macOS, deprecated: 10000, message: "Use `assertSnapshots(of:…:)` instead.")
@available(tvOS, deprecated: 10000, message: "Use `assertSnapshots(of:…:)` instead.")
@available(watchOS, deprecated: 10000, message: "Use `assertSnapshots(of:…:)` instead.")
public func assertSnapshots<Value, Format>(
  matching value: @autoclosure () throws -> Value,
  as strategies: [String: Snapshotting<Value, Format>],
  record recording: Bool = false,
  timeout: TimeInterval = 5,
  file: StaticString = #file,
  testName: String = #function,
  line: UInt = #line
) {
  assertSnapshots(
    of: try value(),
    as: strategies,
    record: recording,
    timeout: timeout,
    file: file,
    testName: testName,
    line: line
  )
}

@available(iOS, deprecated: 10000, message: "Use `assertSnapshots(of:…:)` instead.")
@available(macOS, deprecated: 10000, message: "Use `assertSnapshots(of:…:)` instead.")
@available(tvOS, deprecated: 10000, message: "Use `assertSnapshots(of:…:)` instead.")
@available(watchOS, deprecated: 10000, message: "Use `assertSnapshots(of:…:)` instead.")
public func assertSnapshots<Value, Format>(
  matching value: @autoclosure () throws -> Value,
  as strategies: [Snapshotting<Value, Format>],
  record recording: Bool = false,
  timeout: TimeInterval = 5,
  file: StaticString = #file,
  testName: String = #function,
  line: UInt = #line
) {
  assertSnapshots(
    of: try value(),
    as: strategies,
    record: recording,
    timeout: timeout,
    file: file,
    testName: testName,
    line: line
  )
}

@available(iOS, deprecated: 10000, message: "Use `verifySnapshot(of:…:)` instead.")
@available(macOS, deprecated: 10000, message: "Use `verifySnapshot(of:…:)` instead.")
@available(tvOS, deprecated: 10000, message: "Use `verifySnapshot(of:…:)` instead.")
@available(watchOS, deprecated: 10000, message: "Use `verifySnapshot(of:…:)` instead.")
public func verifySnapshot<Value, Format>(
  matching value: @autoclosure () throws -> Value,
  as snapshotting: Snapshotting<Value, Format>,
  named name: String? = nil,
  record recording: Bool = false,
  snapshotDirectory: String? = nil,
  timeout: TimeInterval = 5,
  file: StaticString = #file,
  testName: String = #function,
  line: UInt = #line
) -> String? {
  verifySnapshot(
    of: try value(),
    as: snapshotting,
    named: name,
    record: recording,
    snapshotDirectory: snapshotDirectory,
    timeout: timeout,
    file: file,
    testName: testName,
    line: line
  )
}
