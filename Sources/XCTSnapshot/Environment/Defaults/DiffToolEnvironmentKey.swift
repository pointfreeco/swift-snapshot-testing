import Foundation

private struct DiffToolEnvironmentKey: SnapshotEnvironmentKey {

  static var defaultValue: DiffTool {
    TestingSystem.shared.environment?.diffTool ?? .default
  }
}

extension SnapshotEnvironmentValues {

  public var diffTool: DiffTool {
    get { self[DiffToolEnvironmentKey.self] }
    set { self[DiffToolEnvironmentKey.self] = newValue }
  }
}
