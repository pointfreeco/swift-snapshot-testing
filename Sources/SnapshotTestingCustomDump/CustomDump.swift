import CustomDump
import XCSnapshotTesting

#if !os(visionOS)
@_exported import _SnapshotTestingCustomDump
#endif

extension SyncSnapshot where Output == StringBytes {

    /// A snapshot strategy for comparing any structure based on a
    /// [custom dump](https://github.com/pointfreeco/swift-custom-dump).
    ///
    /// ```swift
    /// try assert(of: user, as: .customDump)
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
    public static var customDump: SyncSnapshot<Input, Output> {
        IdentitySyncSnapshot<StringBytes>.lines.pullback {
            StringBytes(rawValue: String(customDumping: $0))
        }
    }
}
