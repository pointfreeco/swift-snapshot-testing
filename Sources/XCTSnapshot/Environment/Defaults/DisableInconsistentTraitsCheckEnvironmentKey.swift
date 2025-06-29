import Foundation

private struct DisableInconsistentTraitsCheckerEnvironmentKey: SnapshotEnvironmentKey {
    static let defaultValue = false
}

extension SnapshotEnvironmentValues {

    var disableInconsistentTraitsChecker: Bool {
        get { self[DisableInconsistentTraitsCheckerEnvironmentKey.self] }
        set { self[DisableInconsistentTraitsCheckerEnvironmentKey.self] = newValue }
    }
}
