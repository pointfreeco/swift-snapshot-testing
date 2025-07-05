import Foundation

/// A wrapper for string data in a bytes container, supporting UTF-8 encoding/decoding.
///
/// `StringBytes` conforms to `BytesRepresentable` for byte stream serialization
/// and `ExpressibleByStringLiteral` for direct string initialization. It handles
/// UTF-8 encoding when writing to bytes containers and decoding when reading from them.
///
/// - SeeAlso: BytesRepresentable, ExpressibleByStringLiteral
public struct StringBytes: BytesRepresentable, ExpressibleByStringLiteral {

    /// The raw string value stored by this wrapper.
    public let rawValue: String

    /// Initializes a `StringBytes` instance by decoding UTF-8 data from a bytes container.
    ///
    /// - Parameter container: The bytes container to read from.
    /// - Throws: `BytesSerializationError` if decoding fails.
    public init(from container: BytesContainer) throws {
        guard
            let string = String(
                data: try container.read(),
                encoding: .utf8
            )
        else { throw BytesSerializationError() }

        self.rawValue = string
    }

    /// Initializes a `StringBytes` instance directly from a string.
    ///
    /// - Parameter rawValue: The string value to wrap.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Supports string literal initialization for `StringBytes`.
    ///
    /// - Parameter value: The string literal value.
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    /// Serializes the string value as UTF-8 data into a bytes container.
    ///
    /// - Parameter container: The bytes container to write to.
    /// - Throws: Any error occurring during writing.
    public func serialize(to container: BytesContainer) throws {
        try container.write(Data(rawValue.utf8))
    }
}

extension IdentitySyncSnapshot<StringBytes> {
    /// A snapshot strategy for comparing strings based on line-by-line equality.
    ///
    /// Uses `.lines` as the attachment generator and saves files with `.txt` extensions.
    public static let lines = Self(
        pathExtension: "txt",
        attachmentGenerator: .lines
    )
}
