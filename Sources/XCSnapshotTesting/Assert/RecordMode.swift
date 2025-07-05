import Foundation

/// Specifies the recording behavior for snapshots during testing.
///
/// Adjusts whether and how snapshot files are created or updated during test execution.
public enum RecordMode: Int16, Sendable {

    /// Never records new snapshots. Tests fail if results differ from existing ones; no files are updated.
    case never

    /// Records only if a snapshot is missing. Existing snapshots are not replaced, even if mismatches occur.
    case missing

    /// Records snapshots only when tests fail due to a mismatch. Useful for automatically updating failing snapshots.
    case failed

    /// Always records snapshots, overwriting any existing files. Use to intentionally update all snapshots after UI changes.
    case all
}
