import Foundation

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
  public static let data = Self(
    pathExtension: nil,
    attachmentGenerator: .data
  )
}

extension SyncSnapshot<Data, DataBytes> {
  /// A snapshot strategy for comparing strings based on equality.
  public static let data = IdentitySyncSnapshot.data.map {
    $0.pullback { .init(rawValue: $0) }
  }
}
