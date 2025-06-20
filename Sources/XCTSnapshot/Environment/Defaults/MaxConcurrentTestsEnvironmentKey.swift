import Foundation

private struct MaxConcurrentTestsEnvironmentKey: SnapshotEnvironmentKey {

  static var defaultValue: Int {
    TestingSystem.shared.environment?.maxConcurrentTests ?? 3
  }
}

extension SnapshotEnvironmentValues {

  public var maxConcurrentTests: Int {
    get { self[MaxConcurrentTestsEnvironmentKey.self] }
    set {
      precondition(newValue >= 1)
      self[MaxConcurrentTestsEnvironmentKey.self] = newValue
    }
  }
}
