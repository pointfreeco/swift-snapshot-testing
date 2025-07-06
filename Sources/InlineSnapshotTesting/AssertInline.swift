import Foundation
@_spi(Internals) import XCSnapshotTesting

#if canImport(SwiftSyntax601)
@_spi(Internals) import XCSnapshotTesting
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder

/// Asserts that a given value matches an inline string snapshot using the specified snapshot testing strategy.
///
/// This function compares the output of a value—evaluated lazily—with an inline snapshot string, which is stored directly in your test source code.
/// If the output does not match the inline snapshot, the test will fail and optionally provide a descriptive message.
/// You can optionally record new snapshots, customize serialization, and specify the snapshot comparison strategy.
///
/// - Parameters:
///   - value: A closure that returns the value to compare against the snapshot. This is evaluated only when the assertion runs.
///   - snapshot: The snapshot testing strategy to use for serialization and comparison.
///   - message: An optional closure that returns a description for test results. Defaults to an empty string.
///   - record: An optional mode indicating whether to record a new reference snapshot. If `nil`, recording is determined automatically.
///   - timeout: The number of seconds to wait for the snapshot operation to complete. Defaults to 5.
///   - name: An optional name to distinguish this snapshot from others in the same test.
///   - serialization: The strategy used to serialize the snapshot data. Defaults to `DataSerialization()`.
///   - closureDescriptor: An optional descriptor describing the inline snapshot’s location. Typically not needed unless implementing custom helpers.
///   - expected: An optional closure that returns a previously generated snapshot value. When omitted, the expected value will be populated inline at the call site.
///   - isolation: Optionally specify an actor for input evaluation, supporting thread/actor isolation. Defaults to current context.   
///   - fileID: The file ID in which the assertion was called. Defaults to the file ID of the test case.
///   - filePath: The file path in which the assertion was called. Defaults to the file path of the test case.
///   - function: The function name in which the assertion was called. Defaults to the test method name.
///   - line: The line number on which the assertion was called. Defaults to the line number of the call site.
///   - column: The column on which the assertion was called. Defaults to the column number of the call site.
/// - Throws: Rethrows any error thrown by the value provider or snapshot strategy.
/// - Important: When using the Swift Testing framework, you must explicitly set the @Suite(.finalizeSnapshots) trait to ensure inline snapshots are written correctly.
/// - SeeAlso: <doc:InlineSnapshotTesting>
public func assertInline<Input: Sendable, Output: BytesRepresentable>(
    of value: @autoclosure @Sendable () async throws -> Input,
    as snapshot: AsyncSnapshot<Input, Output>,
    message: @autoclosure @escaping @Sendable () -> String = "",
    record: RecordMode? = nil,
    timeout: TimeInterval = 5,
    name: String? = nil,
    serialization: DataSerialization = DataSerialization(),
    closureDescriptor: SnapshotClosureDescriptor = SnapshotClosureDescriptor(),
    matches expected: (@Sendable () -> Output.RawValue)? = nil,
    isolation: isolated Actor? = #isolation,
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
) async throws {
    let engine = SnapshotInlineEngine<XCSnapshotTesting.Async<Input, Output>>(
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
        try closureDescriptor.fail(
            failure.message,
            fileID: fileID,
            file: filePath,
            line: line,
            column: column
        )
    default:
        try TestingSystem.shared.record(
            message: failure.message,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }
}

/// Asserts that a value matches an inline string snapshot using a snapshot testing strategy.
///
/// This function compares the output of a value—evaluated lazily—with an inline snapshot string
/// stored directly in your test source code. If the output does not match the inline snapshot,
/// the test will fail and optionally provide a descriptive message. You can optionally record new
/// snapshots, customize serialization, and specify the snapshot comparison strategy.
///
/// - Parameters:
///   - value: A closure that returns the value to compare against the snapshot. This is evaluated only when the assertion runs.
///   - snapshot: The snapshot testing strategy to use for serialization and comparison.
///   - message: An optional closure that returns a description for test results. Defaults to an empty string.
///   - record: An optional mode indicating whether to record a new reference snapshot. If `nil`, recording is determined automatically.
///   - timeout: The number of seconds to wait for the snapshot operation to complete. Defaults to 5.
///   - name: An optional name to distinguish this snapshot from others in the same test.
///   - serialization: The strategy used to serialize the snapshot data. Defaults to `DataSerialization()`.
///   - closureDescriptor: An optional descriptor for the inline snapshot’s location. Typically not needed unless implementing custom helpers.
///   - expected: An optional closure that returns a previously generated snapshot value. When omitted, the expected value will be populated inline at the call site.
///   - fileID: The file ID in which the assertion was called. Defaults to the file ID of the test case.
///   - filePath: The file path in which the assertion was called. Defaults to the file path of the test case.
///   - function: The function name in which the assertion was called. Defaults to the test method name.
///   - line: The line number on which the assertion was called. Defaults to the line number of the call site.
///   - column: The column on which the assertion was called. Defaults to the column number of the call site.
/// - Throws: Rethrows any error thrown by the value provider or snapshot strategy.
/// - Important: When using the Swift Testing framework, you must explicitly set the @Suite(.finalizeSnapshots) trait to ensure inline snapshots are written correctly.
/// - SeeAlso: <doc:InlineSnapshotTesting>
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
    let engine = SnapshotInlineEngine<Sync<Input, Output>>(
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
        try closureDescriptor.fail(
            failure.message,
            fileID: fileID,
            file: filePath,
            line: line,
            column: column
        )
    default:
        try TestingSystem.shared.record(
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
