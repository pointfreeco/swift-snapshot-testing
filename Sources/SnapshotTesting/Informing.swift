import Foundation

/// The ability to generate user messages for recorded snapshots and failed tests
public struct Informing<Format> {
  public let snapshotRecorded: (_ testName: String, _ snapshotFileUrl: URL) -> String
  public let testFailed: (_ testName: String, _ snapshotFileUrl: URL, _ failedSnapshotFileUrl: URL) -> String

  /// Creates a new `Informing`
  ///
  /// - Parameters:
  ///   - snapshotRecorded: A function used to generate a message for a new snapshot recording
  ///   - testName: Name of the test for which the snapshot was recorded
  ///   - snapshotFileUrl: Url to the snapshot file
  ///   - testFailed: A function used to generate a message for a test failure
  ///   - testName: Name of the test that failed
  ///   - snapshotFileUrl: Url to the snapshot file
  ///   - failedSnapshotFileUrl: Url to the failed snapshot file
  public init(
    snapshotRecorded: @escaping (_ testName: String, _ snapshotFileUrl: URL) -> String,
    testFailed: @escaping (_ testName: String, _ snapshotFileUrl: URL, _ failedSnapshotFileUrl: URL) -> String
    ) {
    self.snapshotRecorded = snapshotRecorded
    self.testFailed = testFailed
  }
}

public extension Informing {
  public static var basic: Informing {
    return Informing(
      snapshotRecorded: { (testName, snapshotFileUrl) -> String in
        return "open \"\(snapshotFileUrl.path)\""
      },
      testFailed: { (testName, snapshotFileUrl, failedSnapshotFileUrl) -> String in
        return "@\(minus)\n\"\(snapshotFileUrl.path)\"\n@\(plus)\n\"\(failedSnapshotFileUrl.path)\""
      }
    )
  }
  public static var ksdiff: Informing {
    return Informing(
      snapshotRecorded: Informing.basic.snapshotRecorded,
      testFailed: { (testName, snapshotFileUrl, failedSnapshotFileUrl) -> String in
        return "ksdiff \"\(snapshotFileUrl.path)\" \"\(failedSnapshotFileUrl.path)\""
      }
    )
  }
}
