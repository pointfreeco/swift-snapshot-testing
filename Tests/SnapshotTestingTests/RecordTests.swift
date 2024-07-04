import SnapshotTesting
import XCTest

class RecordTests: XCTestCase {
  override func tearDown() {
    try? FileManager.default
      .removeItem(at: snapshotURL().deletingLastPathComponent())
    try? FileManager.default
      .createDirectory(at: snapshotURL().deletingLastPathComponent(), withIntermediateDirectories: true)
  }

  func testRecordNever() {
    let snapshotURL = snapshotURL()

    XCTExpectFailure {
      withSnapshotTesting(record: .never) {
        assertSnapshot(of: 42, as: .json)
      }
    } issueMatcher: {
      $0.compactDescription == """
        failed - The file “testRecordNever.1.json” couldn’t be opened because there is no such file.
        """
    }

    XCTAssertEqual(
      FileManager.default.fileExists(atPath: snapshotURL.path),
      false
    )
  }

  func testRecordMissing() {
    let snapshotURL = snapshotURL()
    try? FileManager.default.removeItem(at: snapshotURL)

    XCTExpectFailure {
      withSnapshotTesting(record: .missing) {
        assertSnapshot(of: 42, as: .json)
      }
    } issueMatcher: {
      $0.compactDescription.hasPrefix("""
        failed - No reference was found on disk. Automatically recorded snapshot: …
        """)
    }

    try XCTAssertEqual(
      String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self),
      "42"
    )
  }

  func testRecordMissing_ExistingFile() throws {
    let snapshotURL = snapshotURL()
    try? FileManager.default.removeItem(at: snapshotURL)
    try Data("999".utf8).write(to: snapshotURL)

    XCTExpectFailure {
      withSnapshotTesting(record: .missing) {
        assertSnapshot(of: 42, as: .json)
      }
    } issueMatcher: {
      $0.compactDescription.hasPrefix("""
        failed - Snapshot does not match reference.
        """)
    }

    try XCTAssertEqual(
      String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self),
      "999"
    )
  }

  func testRecordAll_Fresh() throws {
    let snapshotURL = snapshotURL()
    try? FileManager.default.removeItem(at: snapshotURL)

    XCTExpectFailure {
      withSnapshotTesting(record: .all) {
        assertSnapshot(of: 42, as: .json)
      }
    } issueMatcher: {
      $0.compactDescription.hasPrefix("""
        failed - Record mode is on. Automatically recorded snapshot: …
        """)
    }

    try XCTAssertEqual(
      String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self),
      "42"
    )
  }

  func testRecordAll_Overwrite() throws {
    let snapshotURL = snapshotURL()
    try? FileManager.default.removeItem(at: snapshotURL)
    try Data("999".utf8).write(to: snapshotURL)

    XCTExpectFailure {
      withSnapshotTesting(record: .all) {
        assertSnapshot(of: 42, as: .json)
      }
    } issueMatcher: {
      $0.compactDescription.hasPrefix("""
        failed - Record mode is on. Automatically recorded snapshot: …
        """)
    }

    try XCTAssertEqual(
      String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self),
      "42"
    )
  }

  func testRecordFailed_WhenFailure() throws {
    let snapshotURL = snapshotURL()
    try? FileManager.default.removeItem(at: snapshotURL)
    try Data("999".utf8).write(to: snapshotURL)

    XCTExpectFailure {
      withSnapshotTesting(record: .failed) {
        assertSnapshot(of: 42, as: .json)
      }
    } issueMatcher: {
      $0.compactDescription.hasPrefix("""
        failed - Snapshot does not match reference. A new snapshot was automatically recorded.
        """)
    }

    try XCTAssertEqual(
      String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self),
      "42"
    )
  }

  func testRecordFailed_NoFailure() throws {
    let snapshotURL = snapshotURL()
    try? FileManager.default.removeItem(at: snapshotURL)
    try Data("42".utf8).write(to: snapshotURL)
    let modifiedDate = try FileManager.default
      .attributesOfItem(atPath: snapshotURL.path)[FileAttributeKey.modificationDate] as! Date

    withSnapshotTesting(record: .failed) {
      assertSnapshot(of: 42, as: .json)
    }

    try XCTAssertEqual(
      String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self),
      "42"
    )
    XCTAssertEqual(
      try FileManager.default
        .attributesOfItem(atPath: snapshotURL.path)[FileAttributeKey.modificationDate] as! Date,
      modifiedDate
    )
  }

  func snapshotURL(_ function: StaticString = #function) ->  URL {
    let fileURL = URL(fileURLWithPath: #file, isDirectory: false)
    let fileName = fileURL.deletingPathExtension().lastPathComponent
    return fileURL
      .deletingLastPathComponent()
      .appendingPathComponent("__Snapshots__")
      .appendingPathComponent(fileName)
      .appendingPathComponent("\(String(describing: function).dropLast(2)).1.json")
  }
}
