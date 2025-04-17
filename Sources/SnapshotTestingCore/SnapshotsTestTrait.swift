/// A type representing the configuration of snapshot testing.
public struct _SnapshotsTestTrait: Sendable {
  public let isRecursive = true
  package let configuration: SnapshotTestingConfiguration

  package init(configuration: SnapshotTestingConfiguration) {
    self.configuration = configuration
  }
}
