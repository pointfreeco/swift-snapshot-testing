public struct SnapshotURL: Sendable, Hashable {

  public let path: StaticString

  public init(path: StaticString) {
    self.path = path
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    String(describing: lhs.path) == String(describing: rhs.path)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(String(describing: path))
  }
}
