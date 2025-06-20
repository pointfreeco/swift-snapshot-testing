import Foundation

/// Controls when new snapshots are recorded during tests.
public enum RecordMode: Int16, Sendable {

  /// Prevents recording of any new snapshots.
  ///
  /// Tests will fail if current snapshots don't match results, but no automatic updates will occur.
  case never

  /// Records only missing or modified snapshots.
  ///
  /// If a snapshot already exists, it won't be replaced even if mismatches occur.
  case missing

  case failed

  /// Records snapshots on every execution, overwriting existing ones.
  ///
  /// Useful for intentionally updating snapshots after UI/UX changes.
  case all
}
