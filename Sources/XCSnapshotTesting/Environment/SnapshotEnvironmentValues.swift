import Foundation

/// A collection of values that configure the snapshot testing environment.
///
/// `SnapshotEnvironmentValues` provides a type-safe way to store and retrieve configuration values for snapshot testing.
/// It uses a subscript syntax with keys conforming to `SnapshotEnvironmentKey` to access and modify environment settings.
///
/// ```swift
/// struct MyEnvironmentKey: SnapshotEnvironmentKey {
///     typealias Value = Int
///     static let defaultValue = 42
/// }
///
/// try await withTestingEnvironment {
///     $0[MyEnvironmentKey.self] = 100
/// } operation: {
///     print(SnapshotEnvironment.current[MyEnvironmentKey.self]) // prints 100
/// }
/// ```
public struct SnapshotEnvironmentValues: Sendable {

    @TaskLocal static var current: SnapshotEnvironmentValues?

    private var values: [ObjectIdentifier: Sendable] = [:]

    init() {}

    /// Accesses or sets a configuration value associated with a specific key.
    ///
    /// This subscript provides type-safe access to configuration values stored in `SnapshotEnvironmentValues`.
    /// It uses keys conforming to `SnapshotEnvironmentKey` to retrieve or modify values.
    ///
    /// - Parameter key: The type of key identifying the configuration value.
    /// - Returns: The stored value for the provided key. If no value is set, returns the key's default value.
    public subscript<Key: SnapshotEnvironmentKey>(_ key: Key.Type) -> Key.Value {
        get {
            values[ObjectIdentifier(key)] as? Key.Value ?? Key.defaultValue
        }
        set {
            values[ObjectIdentifier(key)] = newValue
        }
    }
}

/// Temporarily modifies the testing environment for the duration of the specified operation.
///
/// This function allows you to safely mutate the testing environment within a defined scope. After the operation completes, the environment is restored to its original state.
///
/// - Parameters:
///   - mutating: A closure that takes a mutable reference to `SnapshotEnvironmentValues` and modifies it as needed.
///   - operation: The asynchronous operation to perform within the modified environment.
///   - isolation: An optional actor used to isolate the operation. Defaults to the current isolation context.
///   - file: The file name for diagnostic purposes. Defaults to the current file.
///   - line: The line number for diagnostic purposes. Defaults to the current line.
///
/// - Returns: The result of the asynchronous operation.
///
/// - Throws: Any error thrown by the operation closure.
///
/// - Note: The changes made to the environment are only in effect for the duration of the operation.
public func withTestingEnvironment<R: Sendable>(
    _ mutating: @Sendable (inout SnapshotEnvironmentValues) -> Void,
    operation: () async throws -> R,
    isolation: isolated Actor? = #isolation,
    file: String = #file,
    line: UInt = #line
) async rethrows -> R {
    var argumentValues = SnapshotEnvironmentValues.current ?? SnapshotEnvironmentValues()
    mutating(&argumentValues)
    return try await SnapshotEnvironmentValues.$current.withValue(
        argumentValues,
        operation: operation,
        isolation: isolation,
        file: file,
        line: line
    )
}

/// Temporarily modifies the testing environment for the duration of the specified operation.
///
/// This function allows you to safely mutate the testing environment within a defined scope. After the operation completes, the environment is restored to its original state.
///
/// - Parameters:
///   - mutating: A closure that takes a mutable reference to `SnapshotEnvironmentValues` and modifies it as needed.
///   - operation: The synchronous operation to perform within the modified environment.
///   - file: The file name for diagnostic purposes. Defaults to the current file.
///   - line: The line number for diagnostic purposes. Defaults to the current line.
///
/// - Returns: The result of the synchronous operation.
///
/// - Throws: Any error thrown by the operation closure.
///
/// - Note: The changes made to the environment are only in effect for the duration of the operation.
public func withTestingEnvironment<R>(
    _ mutating: @Sendable (inout SnapshotEnvironmentValues) -> Void,
    operation: () throws -> R,
    file: String = #file,
    line: UInt = #line
) rethrows -> R {
    var argumentValues = SnapshotEnvironmentValues.current ?? SnapshotEnvironmentValues()
    mutating(&argumentValues)
    return try SnapshotEnvironmentValues.$current.withValue(
        argumentValues,
        operation: operation,
        file: file,
        line: line
    )
}

/// Temporarily modifies the testing environment with specified parameters and executes an asynchronous operation within this modified context.
///
/// This function allows granular control over the testing environment for the duration of the specified asynchronous operation. It combines direct parameter customization (`record`, `diffTool`, etc.) with a closure for additional environment modifications.
///
/// - Parameters:
///   - record: Optionally sets the recording mode for the operation.
///   - diffTool: Optionally specifies a custom diff tool for the operation.
///   - maxConcurrentTests: Optionally limits the number of concurrent tests.
///   - platform: Optionally overrides the platform identifier for snapshot paths.
///   - mutating: A closure that can further modify the `SnapshotEnvironmentValues`.
///   - operation: The asynchronous operation to perform within the modified environment.
///   - isolation: An optional actor used to isolate the operation. Defaults to the current isolation context.
///   - file: The file name for diagnostic purposes. Defaults to the current file.
///   - line: The line number for diagnostic purposes. Defaults to the current line.
///
/// - Returns: The result of the asynchronous operation.
/// - Throws: Any error thrown by the operation closure.
///
/// - Note: The environment changes are only effective for the duration of the operation.
public func withTestingEnvironment<R: Sendable>(
    record: RecordMode? = nil,
    diffTool: DiffTool? = nil,
    maxConcurrentTests: Int? = nil,
    platform: String? = nil,
    environment mutating: (@Sendable (inout SnapshotEnvironmentValues) -> Void),
    operation: () async throws -> R,
    isolation: isolated Actor? = #isolation,
    file: String = #file,
    line: UInt = #line
) async rethrows -> R {
    try await withTestingEnvironment(
        {
            mutatingEnvironmentValues(
                record: record,
                diffTool: diffTool,
                maxConcurrentTests: maxConcurrentTests,
                platform: platform,
                mutating: &$0
            )
            mutating(&$0)
        },
        operation: operation,
        isolation: isolation,
        file: file,
        line: line
    )
}

/// Temporarily modifies the testing environment with specified parameters and executes an asynchronous operation within this modified context.
///
/// This function allows quick configuration of common testing environment parameters for the duration of the specified asynchronous operation.
///
/// - Parameters:
///   - record: Optionally sets the recording mode for the operation.
///   - diffTool: Optionally specifies a custom diff tool for the operation.
///   - maxConcurrentTests: Optionally limits the number of concurrent tests.
///   - platform: Optionally overrides the platform identifier for snapshot paths.
///   - operation: The asynchronous operation to perform within the modified environment.
///   - isolation: An optional actor used to isolate the operation. Defaults to the current isolation context.
///   - file: The file name for diagnostic purposes. Defaults to the current file.
///   - line: The line number for diagnostic purposes. Defaults to the current line.
///
/// - Returns: The result of the asynchronous operation.
/// - Throws: Any error thrown by the operation closure.
///
/// - Note: The environment changes are only effective for the duration of the operation.
public func withTestingEnvironment<R: Sendable>(
    record: RecordMode? = nil,
    diffTool: DiffTool? = nil,
    maxConcurrentTests: Int? = nil,
    platform: String? = nil,
    operation: () async throws -> R,
    isolation: isolated Actor? = #isolation,
    file: String = #file,
    line: UInt = #line
) async rethrows -> R {
    try await withTestingEnvironment(
        {
            mutatingEnvironmentValues(
                record: record,
                diffTool: diffTool,
                maxConcurrentTests: maxConcurrentTests,
                platform: platform,
                mutating: &$0
            )
        },
        operation: operation,
        isolation: isolation,
        file: file,
        line: line
    )
}

/// Temporarily modifies the testing environment with specified parameters and executes a synchronous operation within this modified context.
///
/// This function allows granular control over the testing environment for the duration of the specified synchronous operation. It combines direct parameter customization (`record`, `diffTool`, etc.) with a closure for additional environment modifications.
///
/// - Parameters:
///   - record: Optionally sets the recording mode for the operation.
///   - diffTool: Optionally specifies a custom diff tool for the operation.
///   - maxConcurrentTests: Optionally limits the number of concurrent tests.
///   - platform: Optionally overrides the platform identifier for snapshot paths.
///   - mutating: A closure that can further modify the `SnapshotEnvironmentValues`.
///   - operation: The synchronous operation to perform within the modified environment.
///   - file: The file name for diagnostic purposes. Defaults to the current file.
///   - line: The line number for diagnostic purposes. Defaults to the current line.
///
/// - Returns: The result of the synchronous operation.
/// - Throws: Any error thrown by the operation closure.
///
/// - Note: The environment changes are only effective for the duration of the operation.
public func withTestingEnvironment<R>(
    record: RecordMode? = nil,
    diffTool: DiffTool? = nil,
    maxConcurrentTests: Int? = nil,
    platform: String? = nil,
    environment mutating: (@Sendable (inout SnapshotEnvironmentValues) -> Void),
    operation: () throws -> R,
    file: String = #file,
    line: UInt = #line
) rethrows -> R {
    try withTestingEnvironment(
        {
            mutatingEnvironmentValues(
                record: record,
                diffTool: diffTool,
                maxConcurrentTests: maxConcurrentTests,
                platform: platform,
                mutating: &$0
            )
            mutating(&$0)
        },
        operation: operation,
        file: file,
        line: line
    )
}

/// Temporarily modifies the testing environment with specified parameters and executes a synchronous operation within this modified context.
///
/// This function allows quick configuration of common testing environment parameters for the duration of the specified synchronous operation.
///
/// - Parameters:
///   - record: Optionally sets the recording mode for the operation.
///   - diffTool: Optionally specifies a custom diff tool for the operation.
///   - maxConcurrentTests: Optionally limits the number of concurrent tests.
///   - platform: Optionally overrides the platform identifier for snapshot paths.
///   - operation: The synchronous operation to perform within the modified environment.
///   - file: The file name for diagnostic purposes. Defaults to the current file.
///   - line: The line number for diagnostic purposes. Defaults to the current line.
///
/// - Returns: The result of the synchronous operation.
/// - Throws: Any error thrown by the operation closure.
///
/// - Note: The environment changes are only effective for the duration of the operation.
public func withTestingEnvironment<R>(
    record: RecordMode? = nil,
    diffTool: DiffTool? = nil,
    maxConcurrentTests: Int? = nil,
    platform: String? = nil,
    operation: () throws -> R,
    file: String = #file,
    line: UInt = #line
) rethrows -> R {
    try withTestingEnvironment(
        {
            mutatingEnvironmentValues(
                record: record,
                diffTool: diffTool,
                maxConcurrentTests: maxConcurrentTests,
                platform: platform,
                mutating: &$0
            )
        },
        operation: operation,
        file: file,
        line: line
    )
}

private func mutatingEnvironmentValues(
    record: RecordMode?,
    diffTool: DiffTool?,
    maxConcurrentTests: Int?,
    platform: String?,
    mutating environment: inout SnapshotEnvironmentValues
) {
    if let record {
        environment.recordMode = record
    }

    if let diffTool {
        environment.diffTool = diffTool
    }

    if let maxConcurrentTests {
        environment.maxConcurrentTests = maxConcurrentTests
    }

    if let platform {
        environment.platform = platform
    }
}
