import Foundation

/// Manager for data serialization and deserialization based on a specific configuration.
///
/// The `DataSerialization` handles conversion between objects conforming to the
/// `BytesRepresentable` protocol and `Data` (serialization) and vice versa (deserialization),
/// using the configuration defined in `DataSerializationConfiguration`.
public struct DataSerialization: Sendable {

    // MARK: - Public properties

    /// Configuration for serialization/deserialization operations.
    ///
    /// Defines parameters such as image scaling, formatting, or other customized options,
    /// accessible via `DataSerializationConfiguration`.
    public var configuration: DataSerializationConfiguration

    // MARK: - Inits

    /// Initializes a `DataSerialization` instance with default configuration.
    ///
    /// The default configuration includes values like `imageScale` defined in
    /// `DataSerializationConfiguration`.
    public init() {
        configuration = .init()
    }

    // MARK: - Public methods

    /// Deserializes binary data into an instance of the specified type.
    ///
    /// - Parameter bytesType: Type of object to create (must conform to `BytesRepresentable`).
    /// - Parameter data: Binary data to convert.
    /// - Returns: An instance of the `Bytes` type created from the data.
    /// - Throws: Errors if deserialization fails.
    public func deserialize<Bytes: BytesRepresentable>(
        _ bytesType: Bytes.Type,
        from data: Data
    ) throws -> Bytes {
        let container = BytesContainer.readOnly(data, with: configuration)
        return try Bytes(from: container)
    }

    /// Serializes an object into binary data.
    ///
    /// - Parameter bytes: Object to serialize (must conform to `BytesRepresentable`).
    /// - Returns: Binary data resulting from serialization.
    /// - Throws: Errors if serialization fails.
    public func serialize<Bytes: BytesRepresentable>(_ bytes: Bytes) throws -> Data {
        let container = BytesContainer.writeOnly(with: configuration)
        try bytes.serialize(to: container)
        return container.data
    }
}
