import Foundation

/// Protocol for types that can be serialized/deserialized to/from a byte container.
///
/// Types conforming to `BytesRepresentable` must be able to:
/// 1. Create an instance from a `BytesContainer` (deserialization).
/// 2. Write their data to a `BytesContainer` (serialization).
///
/// This protocol is essential for snapshot testing, enabling objects to be converted into binary data
/// for comparison.
public protocol BytesRepresentable: Sendable {

  associatedtype RawValue

  var rawValue: RawValue { get }

  init(rawValue: RawValue)

  /// Initializes an instance from data stored in the container.
  ///
  /// - Parameter container: The byte container containing data to read.
  /// - Throws: An error if deserialization fails.
  init(from container: BytesContainer) throws

  /// Serializes the instance's data and writes it to the provided container.
  ///
  /// - Parameter container: The byte container where data will be stored.
  /// - Throws: An error if serialization fails.
  func serialize(to container: BytesContainer) throws
}
