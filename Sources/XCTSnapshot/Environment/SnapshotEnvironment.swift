import Foundation

@dynamicMemberLookup
public struct SnapshotEnvironment: Sendable {

  public static let current = SnapshotEnvironment()

  fileprivate init() {}

  public subscript<Value>(dynamicMember keyPath: KeyPath<SnapshotEnvironmentValues, Value>) -> Value
  {
    (SnapshotEnvironmentValues.current ?? SnapshotEnvironmentValues())[keyPath: keyPath]
  }
}
