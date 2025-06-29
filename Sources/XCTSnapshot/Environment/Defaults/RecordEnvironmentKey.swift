import Foundation

private struct RecordEnvironmentKey: SnapshotEnvironmentKey {

    static var defaultValue: RecordMode {
        TestingSystem.shared.environment?.recordMode ?? .missing
    }
}

extension SnapshotEnvironmentValues {

    /// The current record mode for snapshot testing.
    ///
    /// This key is used to store and retrieve the ``RecordMode`` value within the environment
    /// of a snapshot test. The default value is determined by the testing system's environment,
    /// falling back to `.missing` if no environment is available.
    public var recordMode: RecordMode {
        get { self[RecordEnvironmentKey.self] }
        set { self[RecordEnvironmentKey.self] = newValue }
    }
}
