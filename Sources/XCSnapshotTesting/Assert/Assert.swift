import Foundation

// MARK: - Assert snapshot

/// Validates a single snapshot of an asynchronously computed input value using a specified snapshot strategy.
///
/// This function serializes and compares the provided input value against a previously recorded snapshot,
/// using the supplied `AsyncSnapshot` strategy and serialization configuration. Designed for use in
/// snapshot and regression testing, it ensures that the current representation of the input matches the stored
/// reference, or updates the reference if recording is enabled.
///
/// - Parameters:
///   - input: An autoclosure that asynchronously produces the input value to be tested. The closure is executed during the assertion.
///   - snapshot: An `AsyncSnapshot` describing how the input should be converted to bytes and compared (e.g., image rendering, text output).
///   - serialization: Controls output transformation details, such as image encoding or precision. Defaults to `.init()`.
///   - name: An optional identifier for the snapshot. Useful to differentiate multiple assertions in a single test method.
///   - recording: Optionally override the snapshot recording mode for this assertion (e.g., `.always` to force update, `.never` to only compare).
///   - snapshotDirectory: Optionally specify a custom directory for stored snapshots, overriding the default.
///   - timeout: Time in seconds before the assertion fails for taking too long. Defaults to zero (no timeout).
///   - isolation: Optionally specify an actor for input evaluation, supporting thread/actor isolation. Defaults to current context.
///   - fileID: The unique identifier for the file in which the assertion appears. Supplied automatically by the compiler.
///   - filePath: The file path where the assertion is called. Supplied automatically by the compiler.
///   - testName: The name of the test function calling the assertion. Supplied automatically by the compiler.
///   - line: The source line number where the assertion is called. Supplied automatically by the compiler.
///   - column: The source column where the assertion is called. Supplied automatically by the compiler.
///
/// - Throws: An error if input evaluation, snapshotting, or comparison fails, or if recording fails in recording mode.
///
/// - Important: For multiple assertions within the same test (e.g., in a loop), supply unique `name` values to
///   avoid snapshot counting issues. Automatic snapshot naming relies on the call site position.
///
/// - Note: The recording mode falls back to session-level or environment settings if not provided.
///   Use testing traits, or ``withTestingEnvironment(record:diffTool:maxConcurrentTests:platform:operation:file:line:)``
///   to control globally.
///
/// - Example:
///   ```swift
///   try await assert(
///     of: view,
///     as: .image(layout: .device(.iPhone15ProMax)),
///     named: "light_mode"
///   )
///   ```
public func assert<Input: Sendable, Output: BytesRepresentable>(
    of input: @Sendable @autoclosure () async throws -> Input,
    as snapshot: AsyncSnapshot<Input, Output>,
    serialization: DataSerialization = DataSerialization(),
    named name: String? = nil,
    record recording: RecordMode? = nil,
    snapshotDirectory: String? = nil,
    timeout: TimeInterval = .zero,
    isolation: isolated Actor? = #isolation,
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    testName: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
) async throws {
    let failure = try await verify(
        of: await input(),
        as: snapshot,
        serialization: serialization,
        named: name,
        record: recording,
        snapshotDirectory: snapshotDirectory,
        timeout: timeout,
        isolation: isolation,
        fileID: fileID,
        file: filePath,
        testName: testName,
        line: line,
        column: column
    )

    guard let message = failure else { return }

    try TestingSystem.shared.record(
        message: message,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )
}

/// Asserts that an asynchronously produced value matches multiple named snapshots, each using a distinct strategy.
///
/// For each entry in the provided dictionary, this function generates an input value asynchronously and compares it
/// against a previously recorded reference snapshot using the corresponding `AsyncSnapshot` strategy. Each assertion
/// uses the key as a unique snapshot name. If in recording mode, the reference is updated instead. Failures are
/// reported using the testing system.
///
/// - Parameters:
///   - input: An autoclosure that asynchronously produces the value to be snapshotted and compared. Evaluated once per strategy.
///   - strategies: A dictionary mapping unique snapshot names to `AsyncSnapshot` strategies, allowing different configurations or formats per assertion.
///   - serialization: Settings for how output is serialized (e.g., image encoding, text precision). Defaults to `.init()`.
///   - recording: Optionally override the recording mode for all snapshots in this assertion (e.g., `.always`, `.never`).
///   - snapshotDirectory: Optionally specify a custom directory for storing or comparing snapshots, overriding the default.
///   - timeout: Maximum seconds to wait for input evaluation per assertion. Defaults to `.zero`.
///   - isolation: Optionally specify an actor context for input evaluation, supporting actor/thread isolation. Defaults to current context.
///   - fileID: The unique identifier of the source file. Provided automatically by the compiler.
///   - filePath: The path to the source file. Provided automatically.
///   - testName: The name of the test function. Provided automatically.
///   - line: The line number of the assertion in the source file. Provided automatically.
///   - column: The column number of the assertion in the source file. Provided automatically.
///
/// - Throws: An error if input evaluation, snapshotting, or comparison fails, or if writing fails in recording mode.
///
/// - Important: Each snapshot uses the dictionary key as its unique name. If you need to assert multiple snapshots within a loop,
///   provide unique keys to prevent snapshot overwrites or counting issues.
///
/// - Example:
///   ```swift
///   try await assert(
///     of: view,
///     as: [
///       "light": .image(layout: .device(.iPhone15ProMax)),
///       "dark": .image(layout: .device(.iPhone15ProMaxDark))
///     ]
///   )
///   ```
public func assert<Input: Sendable, Output: BytesRepresentable>(
    of input: @Sendable @autoclosure () async throws -> Input,
    as strategies: [String: AsyncSnapshot<Input, Output>],
    serialization: DataSerialization = DataSerialization(),
    record recording: RecordMode? = nil,
    snapshotDirectory: String? = nil,
    timeout: TimeInterval = .zero,
    isolation: isolated Actor? = #isolation,
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    testName: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
) async throws {
    for (name, configuration) in strategies {
        try await assert(
            of: await input(),
            as: configuration,
            serialization: serialization,
            named: name,
            record: recording,
            snapshotDirectory: snapshotDirectory,
            timeout: timeout,
            isolation: isolation,
            fileID: fileID,
            file: filePath,
            testName: testName,
            line: line,
            column: column
        )
    }
}

/// Asserts that an asynchronously produced value matches multiple snapshots, each using a different strategy from the provided array.
///
/// For each strategy in the array, this function generates an input value asynchronously and compares it against a previously recorded
/// reference snapshot using the corresponding `AsyncSnapshot` strategy. Each assertion is uniquely named using a combination of the
/// test function and the zero-based index (e.g., `testName().1@1`, `testName().1@2`, ...), ensuring distinct snapshot identities per call site.
///
/// - Parameters:
///   - input: An autoclosure that asynchronously produces the value to be snapshotted and compared. Evaluated once per strategy.
///   - strategies: An array of `AsyncSnapshot` strategies to apply to the input. Each entry results in a separate snapshot assertion.
///   - serialization: Settings for how output is serialized (e.g., image encoding, text precision). Defaults to `.init()`.
///   - recording: Optionally override the recording mode for all snapshots in this assertion (e.g., `.always`, `.never`).
///   - snapshotDirectory: Optionally specify a custom directory for storing or comparing snapshots, overriding the default.
///   - timeout: Maximum seconds to wait for input evaluation per assertion. Defaults to `.zero`.
///   - isolation: Optionally specify an actor context for input evaluation, supporting actor/thread isolation. Defaults to current context.
///   - fileID: The unique identifier of the source file. Provided automatically by the compiler.
///   - filePath: The path to the source file. Provided automatically.
///   - testName: The name of the test function. Provided automatically.
///   - line: The line number of the assertion in the source file. Provided automatically.
///   - column: The column number of the assertion in the source file. Provided automatically.
///
/// - Throws: An error if input evaluation, snapshotting, or comparison fails, or if writing fails in recording mode.
///
/// - Important: Each snapshot uses a unique name based on the test function and its index (e.g., `testName().1@1`). This allows safe use in loops or repeated calls without naming collisions.
///   If you require meaningful snapshot names, prefer the dictionary overload.
///
/// - Example:
///   ```swift
///   let strategies = [
///       .image(layout: .device(.iPhone15ProMax)),
///       .image(precision: 0.95)
///   ]
///   try await assert(
///     of: view,
///     as: strategies
///   )
///   ```
public func assert<Input: Sendable, Output: BytesRepresentable>(
    of input: @Sendable @autoclosure () async throws -> Input,
    as strategies: [AsyncSnapshot<Input, Output>],
    serialization: DataSerialization = DataSerialization(),
    record recording: RecordMode? = nil,
    snapshotDirectory: String? = nil,
    timeout: TimeInterval = .zero,
    isolation: isolated Actor? = #isolation,
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    testName: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
) async throws {
    let uniqueID = TestingSession.shared.forLoop(
        fileID: fileID,
        filePath: filePath,
        function: String(describing: testName),
        line: line,
        column: column
    )

    for (index, strategy) in strategies.enumerated() {
        try await assert(
            of: await input(),
            as: strategy,
            serialization: serialization,
            named: "\(uniqueID)@\(index + 1)",
            record: recording,
            snapshotDirectory: snapshotDirectory,
            timeout: timeout,
            isolation: isolation,
            fileID: fileID,
            file: filePath,
            testName: testName,
            line: line,
            column: column
        )
    }
}

// MARK: - Sync snapshot

/// Asserts that a synchronously produced value matches a previously recorded snapshot using the specified strategy.
///
/// This function serializes and compares the given input value against a stored reference using the provided `SyncSnapshot` strategy
/// and serialization configuration. It is designed for snapshot or regression testing, ensuring the current value matches the reference,
/// or updates the reference if recording is enabled. Failures are reported using the testing system.
///
/// - Parameters:
///   - input: An autoclosure producing the value to be tested. Evaluated during the assertion.
///   - snapshot: The `SyncSnapshot` strategy describing how to serialize and compare the input (e.g., as an image, as text).
///   - serialization: Settings for output transformation, such as image encoding or precision. Defaults to `.init()`.
///   - name: An optional identifier for the snapshot. Useful for disambiguating multiple assertions in a single test method.
///   - recording: Optionally override the recording mode for this assertion (e.g., `.always` to update, `.never` to only compare).
///   - snapshotDirectory: Optionally specify a custom directory for stored snapshots, overriding the default.
///   - timeout: Time in seconds before the assertion fails if too long. Defaults to 5 seconds.
///   - fileID: The unique identifier of the source file. Provided automatically by the compiler.
///   - filePath: The path to the source file. Provided automatically.
///   - testName: The name of the test function. Provided automatically.
///   - line: The line number of the assertion call. Provided automatically.
///   - column: The column number of the assertion call. Provided automatically.
///
/// - Throws: An error if input evaluation, snapshotting, or comparison fails, or if recording fails when enabled.
///
/// - Important: For multiple assertions within the same test (such as in a loop), supply unique `name` values to avoid snapshot overwrites or collisions. Automatic naming uses the call site location.
///
/// - Note: If `recording` is not provided, global or session-level settings apply. Use test traits or `withTestingEnvironment(record:operation:)` to control recording globally.
///
/// - Example:
///   ```swift
///   try assert(
///     of: renderedView,
///     as: .image(layout: .device(.iPadPro)),
///     named: "dark_mode"
///   )
///   ```
public func assert<Input, Output: BytesRepresentable>(
    of input: @autoclosure () throws -> Input,
    as snapshot: SyncSnapshot<Input, Output>,
    serialization: DataSerialization = DataSerialization(),
    named name: String? = nil,
    record recording: RecordMode? = nil,
    snapshotDirectory: String? = nil,
    timeout: TimeInterval = 5,
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    testName: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
) throws {
    let failure = try verify(
        of: input(),
        as: snapshot,
        serialization: serialization,
        named: name,
        record: recording,
        snapshotDirectory: snapshotDirectory,
        timeout: timeout,
        fileID: fileID,
        file: filePath,
        testName: testName,
        line: line,
        column: column
    )

    guard let message = failure else { return }

    try TestingSystem.shared.record(
        message: message,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )
}

/// Asserts that a synchronously produced value matches multiple named snapshots, each using a distinct strategy.
///
/// For each entry in the provided dictionary, this function compares the input value against a previously recorded reference snapshot
/// using the corresponding `SyncSnapshot` strategy. Each assertion uses the dictionary key as a unique snapshot name. If in recording mode,
/// the reference is updated instead. Failures are reported using the testing system.
///
/// - Parameters:
///   - input: The value to be snapshotted and compared. Used for all strategies.
///   - strategies: A dictionary mapping unique snapshot names to `SyncSnapshot` strategies, allowing different configurations or formats per assertion.
///   - serialization: Settings for how output is serialized (e.g., image encoding, text precision). Defaults to `.init()`.
///   - recording: Optionally override the recording mode for all snapshots in this assertion (e.g., `.always`, `.never`).
///   - snapshotDirectory: Optionally specify a custom directory for storing or comparing snapshots, overriding the default.
///   - timeout: Maximum seconds to wait for each assertion. Defaults to 5.
///   - fileID: The unique identifier of the source file. Provided automatically by the compiler.
///   - filePath: The path to the source file. Provided automatically.
///   - testName: The name of the test function. Provided automatically.
///   - line: The line number of the assertion in the source file. Provided automatically.
///   - column: The column number of the assertion in the source file. Provided automatically.
///
/// - Throws: An error if snapshotting or comparison fails, or if writing fails in recording mode.
///
/// - Important: Each snapshot uses the dictionary key as its unique name. If you need to assert multiple snapshots within a loop, provide unique keys to prevent snapshot overwrites or counting issues.
///
/// - Example:
///   ```swift
///   try assert(
///     of: renderedView,
///     as: [
///       "light": .image(layout: .device(.iPadPro)),
///       "dark": .image(layout: .device(.iPadProDark))
///     ]
///   )
///   ```
public func assert<Input, Output: BytesRepresentable>(
    of input: Input,
    as strategies: [String: SyncSnapshot<Input, Output>],
    serialization: DataSerialization = DataSerialization(),
    record recording: RecordMode? = nil,
    snapshotDirectory: String? = nil,
    timeout: TimeInterval = 5,
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    testName: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
) throws {
    for (name, configuration) in strategies {
        try? assert(
            of: input,
            as: configuration,
            serialization: serialization,
            named: name,
            record: recording,
            snapshotDirectory: snapshotDirectory,
            timeout: timeout,
            fileID: fileID,
            file: filePath,
            testName: testName,
            line: line,
            column: column
        )
    }
}

/// Asserts that a synchronously produced value matches multiple snapshots, each using a different strategy from the provided array.
///
/// For each strategy in the array, this function compares the input value against a previously recorded reference snapshot using the
/// corresponding `SyncSnapshot` strategy. Each assertion is uniquely named using a combination of the test function and the index
/// (e.g., `testName().1@1`, `testName().1@2`, ...), ensuring distinct snapshot identities per call site.
///
/// - Parameters:
///   - input: The value to be snapshotted and compared. Used for all strategies.
///   - strategies: An array of `SyncSnapshot` strategies to apply to the input. Each entry results in a separate snapshot assertion.
///   - serialization: Settings for how output is serialized (e.g., image encoding, text precision). Defaults to `.init()`.
///   - recording: Optionally override the recording mode for all snapshots in this assertion (e.g., `.always`, `.never`).
///   - snapshotDirectory: Optionally specify a custom directory for storing or comparing snapshots, overriding the default.
///   - timeout: Maximum seconds to wait for each assertion. Defaults to 5.
///   - fileID: The unique identifier of the source file. Provided automatically by the compiler.
///   - filePath: The path to the source file. Provided automatically.
///   - testName: The name of the test function. Provided automatically.
///   - line: The line number of the assertion in the source file. Provided automatically.
///   - column: The column number of the assertion in the source file. Provided automatically.
///
/// - Throws: An error if snapshotting or comparison fails, or if writing fails in recording mode.
///
/// - Important: Each snapshot uses a unique name based on the test function and its index (e.g., `testName().1@1`). This allows safe use in loops or repeated calls without naming collisions. If you require meaningful snapshot names, prefer the dictionary overload.
///
/// - Example:
///   ```swift
///   let strategies = [
///       .image(layout: .device(.iPadPro)),
///       .image(precision: 0.95)
///   ]
///   try await assert(
///     of: renderedView,
///     as: strategies
///   )
///   ```
public func assert<Input, Output: BytesRepresentable>(
    of input: Input,
    as strategies: [SyncSnapshot<Input, Output>],
    serialization: DataSerialization = DataSerialization(),
    record recording: RecordMode? = nil,
    snapshotDirectory: String? = nil,
    timeout: TimeInterval = 5,
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    testName: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
) async throws {
    for strategy in strategies {
        try? assert(
            of: input,
            as: strategy,
            serialization: serialization,
            record: recording,
            snapshotDirectory: snapshotDirectory,
            timeout: timeout,
            fileID: fileID,
            file: filePath,
            testName: testName,
            line: line,
            column: column
        )
    }
}

/// Validates an asynchronously produced value against a stored snapshot using a specified strategy and serialization configuration.
///
/// This function evaluates the provided input value asynchronously, serializes it using the supplied `AsyncSnapshot` strategy and `DataSerialization`,
/// and compares it to a previously recorded snapshot on disk. If the assertion fails, it returns a descriptive failure message;
/// otherwise, it returns `nil`. Supports optional snapshot recording, custom directories, timeouts, and actor isolation.
///
/// - Parameters:
///   - input: An autoclosure that asynchronously produces the value to snapshot and compare. Executed at assertion time.
///   - snapshot: An `AsyncSnapshot` describing how to serialize and compare the input (e.g., image rendering, text output).
///   - serialization: Settings for output transformation and encoding. Defaults to `.init()`.
///   - name: An optional identifier for the snapshot, used to disambiguate multiple assertions within a test.
///   - recording: Optionally override the recording mode for this assertion (e.g., `.always` to update, `.never` to only compare).
///   - snapshotDirectory: Optionally specify a directory for storing or comparing snapshots, overriding the default.
///   - timeout: Maximum seconds to wait for input evaluation or snapshotting. Defaults to `.zero`.
///   - isolation: Optionally specify an actor for input evaluation, supporting thread/actor isolation. Defaults to current context.
///   - fileID: The unique identifier of the source file. Provided automatically by the compiler.
///   - filePath: The path to the source file. Provided automatically.
///   - testName: The name of the test function. Provided automatically.
///   - line: The line number of the assertion in the source file. Provided automatically.
///   - column: The column number of the assertion in the source file. Provided automatically.
///
/// - Returns: An optional failure message string if the assertion fails; otherwise, `nil`.
///
/// - Throws: An error if input evaluation, snapshotting, comparison, or recording fails.
///
/// - Important: For multiple assertions within the same test (e.g., in a loop), use unique `name` values.
/// - Note: Recording mode falls back to environment or session-level settings if not specified.
public func verify<Input: Sendable, Output: BytesRepresentable>(
    of input: @Sendable @autoclosure () async throws -> Input,
    as snapshot: AsyncSnapshot<Input, Output>,
    serialization: DataSerialization = DataSerialization(),
    named name: String? = nil,
    record recording: RecordMode? = nil,
    snapshotDirectory: String? = nil,
    timeout: TimeInterval = .zero,
    isolation: isolated Actor? = #isolation,
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    testName: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
) async throws -> String? {
    let engine = SnapshotFileEngine<Async<Input, Output>>(
        sourceURL: snapshotDirectory.map {
            URL(fileURLWithPath: $0, isDirectory: true)
        }
    )

    let tester = SnapshotTester(
        engine: engine,
        record: recording,
        timeout: timeout,
        name: name,
        serialization: serialization,
        fileID: fileID,
        filePath: filePath,
        function: testName,
        line: line,
        column: column
    )

    return try await tester(input(), for: snapshot)?.message
}

/// Validates a synchronously produced value against a stored snapshot using a specified strategy and serialization configuration.
///
/// This function evaluates the provided input value, serializes it using the supplied `SyncSnapshot` strategy and `DataSerialization`,
/// and compares it to a previously recorded snapshot on disk. If the assertion fails, it returns a descriptive failure message;
/// otherwise, it returns `nil`. Supports optional snapshot recording, custom directories, and timeouts.
///
/// - Parameters:
///   - input: An autoclosure that produces the value to snapshot and compare. Executed at assertion time.
///   - snapshot: A `SyncSnapshot` describing how to serialize and compare the input (e.g., image rendering, text output).
///   - serialization: Settings for output transformation and encoding. Defaults to `.init()`.
///   - name: An optional identifier for the snapshot, used to disambiguate multiple assertions within a test.
///   - recording: Optionally override the recording mode for this assertion (e.g., `.always` to update, `.never` to only compare).
///   - snapshotDirectory: Optionally specify a directory for storing or comparing snapshots, overriding the default.
///   - timeout: Maximum seconds to wait for input evaluation or snapshotting. Defaults to 5 seconds.
///   - fileID: The unique identifier of the source file. Provided automatically by the compiler.
///   - filePath: The path to the source file. Provided automatically.
///   - testName: The name of the test function. Provided automatically.
///   - line: The line number of the assertion in the source file. Provided automatically.
///   - column: The column number of the assertion in the source file. Provided automatically.
///
/// - Returns: An optional failure message string if the assertion fails; otherwise, `nil`.
///
/// - Throws: An error if input evaluation, snapshotting, comparison, or recording fails.
///
/// - Important: For multiple assertions within the same test (e.g., in a loop), use unique `name` values.
/// - Note: Recording mode falls back to environment or session-level settings if not specified.
public func verify<Input, Output: BytesRepresentable>(
    of input: @autoclosure () throws -> Input,
    as snapshot: SyncSnapshot<Input, Output>,
    serialization: DataSerialization = DataSerialization(),
    named name: String? = nil,
    record recording: RecordMode? = nil,
    snapshotDirectory: String? = nil,
    timeout: TimeInterval = 5,
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    testName: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
) throws -> String? {
    let engine = SnapshotFileEngine<Sync<Input, Output>>(
        sourceURL: snapshotDirectory.map {
            URL(fileURLWithPath: $0, isDirectory: true)
        }
    )

    let tester = SnapshotTester(
        engine: engine,
        record: recording,
        timeout: timeout,
        name: name,
        serialization: serialization,
        fileID: fileID,
        filePath: filePath,
        function: testName,
        line: line,
        column: column
    )

    return try tester(input(), for: snapshot)?.message
}
