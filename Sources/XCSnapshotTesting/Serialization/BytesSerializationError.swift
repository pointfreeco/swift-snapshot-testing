import Foundation

/// Represents an error that occurred during binary data serialization or deserialization.
///
/// This structure indicates failures in operations involving conversion of data to or from binary formats,
/// such as reading/writing in a `BytesContainer`.
public struct BytesSerializationError: Error {

    /// Initializes an instance of `BytesSerializationError`.
    ///
    /// This initializer creates a basic error instance, typically used to indicate generic failures during
    /// serialization/deserialization processes.
    public init() {}
}
