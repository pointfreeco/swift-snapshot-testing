import Foundation

/// A dynamic environment container for accessing snapshot testing configuration values.
///
/// `SnapshotEnvironment` provides a convenient way to access configuration values using Swift's `@dynamicMemberLookup` feature.
/// It allows you to retrieve values from the underlying `SnapshotEnvironmentValues` using dynamic key path lookups.
///
/// ```swift
/// struct MyEnvironmentKey: SnapshotEnvironmentKey {
///     typealias Value = Int
///     static let defaultValue = 42
/// }
///
/// extension SnapshotEnvironmentValues {
///     var myEnvironment: Int {
///         get { self[MyEnvironmentKey.self] }
///         set { self[MyEnvironmentKey.self] = newValue }
///     }
/// }
///
/// let value = SnapshotEnvironment.current.myEnvironment // results 42
/// ```
@dynamicMemberLookup
public struct SnapshotEnvironment: Sendable {

    /// The current snapshot environment instance available in the testing context.
    public static let current = SnapshotEnvironment()

    fileprivate init() {}

    /// Provides dynamic member lookup access to values stored in `SnapshotEnvironmentValues`.
    ///
    /// This subscript allows you to retrieve configuration values from the snapshot testing environment
    /// using key paths to properties defined in `SnapshotEnvironmentValues`.
    ///
    /// - Parameter keyPath: A key path to the value in `SnapshotEnvironmentValues`.
    /// - Returns: The value associated with the given key path.
    ///
    /// Example usage:
    /// ```swift
    /// let currentDiffTool = SnapshotEnvironment.current.diffTool
    /// let currentRecordMode = SnapshotEnvironment.current.recordMode
    /// ```
    ///
    /// - Note: This subscript provides type-safe access to environment values and is made possible
    ///   by Swift's `@dynamicMemberLookup` feature.
    public subscript<Value>(dynamicMember keyPath: KeyPath<SnapshotEnvironmentValues, Value>) -> Value {
        (SnapshotEnvironmentValues.current ?? SnapshotEnvironmentValues())[keyPath: keyPath]
    }

    /// Accesses configuration values stored in `SnapshotEnvironmentValues` using keys that conform to `SnapshotEnvironmentKey`.
    ///
    /// This subscript allows you to retrieve values from the snapshot testing environment configuration.
    /// Each value is associated with a specific key type that conforms to `SnapshotEnvironmentKey`.
    ///
    /// - Parameter key: The type of key identifying the configuration value to access.
    /// - Returns: The value associated with the provided key.
    ///
    /// Example usage:
    /// ```swift
    /// let diffTool = SnapshotEnvironment.current[DiffToolKey.self]
    /// print(diffTool(currentFilePath: "file://old.png", failedFilePath: "file://new.png"))
    /// ```
    public subscript<Key: SnapshotEnvironmentKey>(_ key: Key.Type) -> Key.Value {
        (SnapshotEnvironmentValues.current ?? SnapshotEnvironmentValues())[key]
    }
}
