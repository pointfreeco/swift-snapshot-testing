import Foundation

@dynamicMemberLookup
public enum SnapshotEnvironment: Sendable {

  public static subscript<Value>(dynamicMember keyPath: KeyPath<SnapshotEnvironmentValues, Value>) -> Value {
    (SnapshotEnvironmentValues.current ?? SnapshotEnvironmentValues())[keyPath: keyPath]
  }
}
