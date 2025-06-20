import Foundation

public struct StringBytes: BytesRepresentable, ExpressibleByStringLiteral {
  
  public let rawValue: String

  public init(from container: BytesContainer) throws {
    guard let string = String(
      data: try container.read(),
      encoding: .utf8
    ) else {
      throw BytesSerializationError()
    }
    
    self.rawValue = string
  }
  
  public init(rawValue: String) {
    self.rawValue = rawValue
  }
  
  public init(stringLiteral value: String) {
    self.init(rawValue: value)
  }
  
  public func serialize(to container: BytesContainer) throws {
    try container.write(Data(rawValue.utf8))
  }
}

extension IdentitySyncSnapshot<StringBytes> {
  /// A snapshot strategy for comparing strings based on equality.
  public static let lines = Self(
    pathExtension: "txt",
    attachmentGenerator: .lines
  )
}
