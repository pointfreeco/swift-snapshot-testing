import Foundation
import Testing
@_spi(Internals) import XCSnapshotTesting

public struct RecordTrait: SuiteTrait, TestTrait {
    public let isRecursive = true
    let recordMode: RecordMode
}

extension Trait where Self == RecordTrait {

    /// Adds record mode configuration to a suite or test.
    ///
    /// Use this trait to specify the snapshot recording mode for the test or suite.
    /// This is typically used in snapshot testing to control whether expected
    /// snapshots are created or updated.
    ///
    /// The default value is `.missing`, which means a snapshot will only be recorded if no file is found (i.e., a snapshot is missing).
    ///
    /// ## Examples
    ///
    /// ```swift
    /// @Test(.record(.all))
    /// func testRecordAllSnapshots() async throws {
    ///     // Test code here
    /// }
    ///
    /// @Suite(.record(.never))
    /// struct NoSnapshotRecordingTests {
    ///     // Suite contents here
    /// }
    /// ```
    ///
    /// - Parameter recordMode: The `RecordMode` value to use when running tests.
    ///   This controls whether snapshots should be recorded (created/updated) or not.
    /// - Returns: A `RecordTrait` configured with the given `recordMode`.
    public static func record(_ recordMode: RecordMode) -> Self {
        .init(recordMode: recordMode)
    }
}
