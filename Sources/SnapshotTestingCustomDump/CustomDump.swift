import CustomDump
import SnapshotTesting

extension Snapshotting where Format == String {
  /// A snapshot strategy for comparing any structure based on a
  /// [custom dump](https://github.com/pointfreeco/swift-custom-dump).
  ///
  /// ```swift
  /// assertSnapshot(of: user, as: .customDump)
  /// ```
  ///
  /// Records:
  ///
  /// ```
  /// User(
  ///   bio: "Blobbed around the world.",
  ///   id: 1,
  ///   name: "Blobby"
  /// )
  /// ```
  public static var customDump: Snapshotting {
    SimplySnapshotting.lines.pullback(String.init(customDumping:))
  }
}
