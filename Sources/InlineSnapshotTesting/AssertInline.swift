import Foundation
@preconcurrency import XCTest
@_spi(Internals) import XCTSnapshot

#if canImport(SwiftSyntax601)
@_spi(Internals) import XCTSnapshot
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import XCTest

/// Asserts that a given value matches an inline string snapshot.
///
/// See <doc:InlineSnapshotTesting> for more info.
///
/// - Parameters:
///   - value: A value to compare against a snapshot.
///   - snapshot: A strategy for snapshot and comparing values.
///   - message: An optional description of the assertion, for inclusion in test results.
///   - isRecording: Whether or not to record a new reference.
///   - timeout: The amount of time a snapshot must be generated in.
///   - closureDescriptor: An optional description of where the snapshot is inlined. This parameter
///     should be omitted unless you are writing a custom helper that calls this function under
///     the hood. See ``SnapshotClosureDescriptor`` for more.
///   - expected: An optional closure that returns a previously generated snapshot. When omitted,
///     the library will automatically write a snapshot into your test file at the call sight of
///     the assertion.
///   - fileID: The file ID in which failure occurred. Defaults to the file ID of the test case in
///     which this function was called.
///   - file: The file in which failure occurred. Defaults to the file path of the test case in
///     which this function was called.
///   - function: The function where the assertion occurs. The default is the name of the test
///     method where you call this function.
///   - line: The line number on which failure occurred. Defaults to the line number on which this
///     function was called.
///   - column: The column on which failure occurred. Defaults to the column on which this
///     function was called.
public func assertInline<Input: Sendable, Output: BytesRepresentable>(
  of value: @autoclosure @Sendable () throws -> Input,
  as snapshot: AsyncSnapshot<Input, Output>,
  message: @autoclosure @escaping @Sendable () -> String = "",
  record: RecordMode? = nil,
  timeout: TimeInterval = 5,
  name: String? = nil,
  serialization: DataSerialization = DataSerialization(),
  closureDescriptor: SnapshotClosureDescriptor = SnapshotClosureDescriptor(),
  matches expected: (@Sendable () -> Output.RawValue)? = nil,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) async throws {
  preconditionSwiftEnvironment(
    file: filePath,
    line: line
  )

  let engine = InlineSnapshotEngine<XCTSnapshot.Async<Input, Output>>(
    expected: expected,
    message: message,
    closureDescriptor: closureDescriptor
  )

  let tester = SnapshotTester(
    engine: engine,
    record: record,
    timeout: timeout,
    name: name,
    serialization: serialization,
    fileID: fileID,
    filePath: filePath,
    function: function,
    line: line,
    column: column
  )

  guard let failure = try await tester(value(), for: snapshot) else {
    return
  }

  switch failure.reason {
  case .doesNotMatch:
    closureDescriptor.fail(
      failure.message,
      fileID: fileID,
      file: filePath,
      line: line,
      column: column
    )
  default:
    TestingSystem.shared.record(
      message: failure.message,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }
}

public func assertInline<Input, Output: BytesRepresentable>(
  of value: @autoclosure @Sendable () throws -> Input,
  as snapshot: SyncSnapshot<Input, Output>,
  message: @autoclosure @escaping @Sendable () -> String = "",
  record: RecordMode? = nil,
  timeout: TimeInterval = 5,
  name: String? = nil,
  serialization: DataSerialization = DataSerialization(),
  closureDescriptor: SnapshotClosureDescriptor = SnapshotClosureDescriptor(),
  matches expected: (@Sendable () -> Output.RawValue)? = nil,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) throws {
  preconditionSwiftEnvironment(
    file: filePath,
    line: line
  )

  let engine = InlineSnapshotEngine<Sync<Input, Output>>(
    expected: expected,
    message: message,
    closureDescriptor: closureDescriptor
  )

  let tester = SnapshotTester(
    engine: engine,
    record: record,
    timeout: timeout,
    name: name,
    serialization: serialization,
    fileID: fileID,
    filePath: filePath,
    function: function,
    line: line,
    column: column
  )

  guard let failure = try tester(value(), for: snapshot) else {
    return
  }

  switch failure.reason {
  case .doesNotMatch:
    closureDescriptor.fail(
      failure.message,
      fileID: fileID,
      file: filePath,
      line: line,
      column: column
    )
  default:
    TestingSystem.shared.record(
      message: failure.message,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }
}
#else
@available(*, unavailable, message: "'assertInline' requires 'swift-syntax' >= 509.0.0")
public func assertInline<Input: Sendable, Output: BytesRepresentable>(
  of value: @autoclosure @Sendable () throws -> Input,
  as snapshot: AsyncSnapshot<Input, Output>,
  message: @autoclosure @escaping @Sendable () -> String = "",
  record: RecordMode? = nil,
  timeout: TimeInterval = 5,
  serialization: DataSerialization = DataSerialization(),
  closureDescriptor: SnapshotClosureDescriptor = SnapshotClosureDescriptor(),
  matches expected: (@Sendable () -> Output.RawValue)? = nil,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) async throws {
  fatalError()
}

@available(*, unavailable, message: "'assertInline' requires 'swift-syntax' >= 509.0.0")
public func assertInline<Input, Output: BytesRepresentable>(
  of value: @autoclosure @Sendable () throws -> Input,
  as snapshot: SyncSnapshot<Input, Output>,
  message: @autoclosure @escaping @Sendable () -> String = "",
  record: RecordMode? = nil,
  timeout: TimeInterval = 5,
  serialization: DataSerialization = DataSerialization(),
  closureDescriptor: SnapshotClosureDescriptor = SnapshotClosureDescriptor(),
  matches expected: (@Sendable () -> Output.RawValue)? = nil,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) throws {
  fatalError()
}
#endif

private func preconditionSwiftEnvironment(
 file filePath: StaticString,
 line: UInt
) {
  if TestingSystem.shared.isSwiftTestingRunning {
    #if compiler(<6.1)
    fatalError(
      """
      The function `assertInline(of:as:)` is available only when:
      - Using the **Swift Testing Framework** with a **Swift compiler version ≥ 6.1**, or
      - Using **XCTest** (any Swift version is supported).
      
      To fix this:
      - If you're using Swift Testing, update your Swift compiler to 6.1 or newer.
      - If you're not using XCTest yet, consider migrating to XCTestCase to avoid compiler \
      version restrictions.
      """,
      file: filePath,
      line: line
    )
    #endif
  }
}
