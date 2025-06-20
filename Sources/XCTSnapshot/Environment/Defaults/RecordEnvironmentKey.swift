import Foundation

private struct RecordEnvironmentKey: SnapshotEnvironmentKey {

  static var defaultValue: RecordMode {
    TestingSystem.shared.environment?.recordMode ?? .missing
  }
}

extension SnapshotEnvironmentValues {

  public var recordMode: RecordMode {
    get { self[RecordEnvironmentKey.self] }
    set { self[RecordEnvironmentKey.self] = newValue }
  }
}
