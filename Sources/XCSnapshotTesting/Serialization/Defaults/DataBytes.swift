import Foundation

/// A wrapper type for `Data` that conforms to `BytesRepresentable`, enabling serialization and deserialization of byte-based data.
///
/// This type provides a convenient way to work with raw byte data through a `Data` value, supporting reading from and writing to `BytesContainer` instances. It is designed for scenarios where direct byte manipulation or inspection is required.
///
/// - SeeAlso:
///    - ``BytesRepresentable``
///    - ``BytesContainer``
public struct DataBytes: BytesRepresentable {

    public let rawValue: Data

    public init(from container: BytesContainer) throws {
        self.rawValue = try container.read()
    }

    public init(rawValue: Data) {
        self.rawValue = rawValue
    }

    public func serialize(to container: BytesContainer) throws {
        try container.write(rawValue)
    }
}

extension IdentitySyncSnapshot<DataBytes> {
    /// A snapshot strategy for comparing strings based on equality.
    public static let data = IdentitySyncSnapshot<DataBytes>(
        pathExtension: nil,
        attachmentGenerator: .data
    )
}
