import Foundation

/// Configuration for parameters used during data serialization/deserialization.
///
/// The `DataSerializationConfiguration` stores specific configuration values, accessible via keys
/// conforming to the `DataSerializationConfigurationKey` protocol.
/// These configurations control behaviors such as image scaling or formatting during data conversion.
///
/// Example extension:
///
///     extension DataSerializationConfiguration {
///         var imageScale: Double {
///             get { self[ImageBytes.ImageScaleKey.self] }
///             set { self[ImageBytes.ImageScaleKey.self] = newValue }
///         }
///     }
///
/// Example access:
///
///     func serialize(to container: BytesContainer) throws {
///         let imageScale = container.configuration.imageScale
///         ...
///     }
public struct DataSerializationConfiguration: Sendable {

    // MARK: - Private properties

    private var values: [ObjectIdentifier: Sendable]

    // MARK: - Inits

    init() {
        self.values = [:]
    }

    // MARK: - Public methods

    /// Accesses or sets a configuration value associated with a specific key.
    ///
    /// - Parameter keyType: The key type identifying the configuration (must conform to
    ///   `DataSerializationConfigurationKey`).
    /// - Returns: The stored value for the provided key. If no value is set, returns the key's default value.
    public subscript<Key: DataSerializationConfigurationKey>(_ keyType: Key.Type) -> Key.Value {
        get { values[ObjectIdentifier(keyType)] as? Key.Value ?? Key.defaultValue }
        set { values[ObjectIdentifier(keyType)] = newValue }
    }
}
