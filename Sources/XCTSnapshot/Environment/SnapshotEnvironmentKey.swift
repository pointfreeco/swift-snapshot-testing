import Foundation

/// A protocol for defining keys that can be used with `SnapshotEnvironmentValues`.
///
/// Conform to this protocol to create custom keys for storing values in the snapshot testing environment.
/// Each key must specify an associated value type and provide a default value.
///
/// ```swift
/// struct MyEnvironmentKey: SnapshotEnvironmentKey {
///     typealias Value = Int
///     static let defaultValue = 42
/// }
/// ```
public protocol SnapshotEnvironmentKey {
    /// The type of value associated with the key.
    associatedtype Value: Sendable

    /// The default value for the key if no value has been explicitly set.
    static var defaultValue: Value { get }
}
