import Foundation

/// Protocol defining keys for serialization/deserialization configurations with default values.
///
/// Types conforming to `DataSerializationConfigurationKey` represent unique keys for specific configurations like
/// image scaling or formatting. Each key must define:
/// 1. An **associated type** (`Value`) representing the configuration value's type.
/// 2. A **static default value** for the key.
public protocol DataSerializationConfigurationKey: Sendable {

    /// Associated type representing the value type for this configuration key.
    associatedtype Value: Sendable

    /// Default value for this key when not explicitly configured.
    ///
    /// Example: For an image scaling configuration key, the default might be `1.0`.
    static var defaultValue: Value { get }
}
