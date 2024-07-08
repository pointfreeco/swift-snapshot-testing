import SnapshotTesting
import XCTest

class RecordTests: XCTestCase {
  var snapshotURL: URL!

  override func setUp() {
    super.setUp()

    let testName = String(
      self.name
        .split(separator: " ")
        .flatMap { String($0).split(separator: ".") }
        .last!
    )
    .prefix(while: { $0 != "]" })
    let fileURL = URL(fileURLWithPath: #file, isDirectory: false)
    let testClassName = fileURL.deletingPathExtension().lastPathComponent
    let testDirectory =
      fileURL
      .deletingLastPathComponent()
      .appendingPathComponent("__Snapshots__")
      .appendingPathComponent(testClassName)
    snapshotURL =
      testDirectory
      .appendingPathComponent("\(testName).1.json")
    try? FileManager.default
      .removeItem(at: snapshotURL.deletingLastPathComponent())
    try? FileManager.default
      .createDirectory(at: testDirectory, withIntermediateDirectories: true)
  }

  override func tearDown() {
    super.tearDown()
    try? FileManager.default
      .removeItem(at: snapshotURL.deletingLastPathComponent())
  }

  #if canImport(Darwin)
    func testRecordNever() {
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
  #endif

  #if canImport(Darwin)
    func testRecordMissing() {
      XCTExpectFailure {
        withSnapshotTesting(record: .missing) {
          assertSnapshot(of: 42, as: .json)
        }
      } issueMatcher: {
        $0.compactDescription.hasPrefix(
          """
          failed - No reference was found on disk. Automatically recorded snapshot: …
          """)
      }

      try XCTAssertEqual(
        String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self),
        "42"
      )
    }
  #endif

  #if canImport(Darwin)
    func testRecordMissing_ExistingFile() throws {
      try Data("999".utf8).write(to: snapshotURL)

      XCTExpectFailure {
        withSnapshotTesting(record: .missing) {
          assertSnapshot(of: 42, as: .json)
        }
      } issueMatcher: {
        $0.compactDescription.hasPrefix(
          """
          failed - Snapshot does not match reference.
          """)
      }

      try XCTAssertEqual(
        String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self),
        "999"
      )
    }
  #endif

  #if canImport(Darwin)
    func testRecordAll_Fresh() throws {
      XCTExpectFailure {
        withSnapshotTesting(record: .all) {
          assertSnapshot(of: 42, as: .json)
        }
      } issueMatcher: {
        $0.compactDescription.hasPrefix(
          """
          failed - Record mode is on. Automatically recorded snapshot: …
          """)
      }

      try XCTAssertEqual(
        String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self),
        "42"
      )
    }
  #endif

  #if canImport(Darwin)
    func testRecordAll_Overwrite() throws {
      try Data("999".utf8).write(to: snapshotURL)

      XCTExpectFailure {
        withSnapshotTesting(record: .all) {
          assertSnapshot(of: 42, as: .json)
        }
      } issueMatcher: {
        $0.compactDescription.hasPrefix(
          """
          failed - Record mode is on. Automatically recorded snapshot: …
          """)
      }

      try XCTAssertEqual(
        String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self),
        "42"
      )
    }
  #endif

  #if canImport(Darwin)
    func testRecordFailed_WhenFailure() throws {
      try Data("999".utf8).write(to: snapshotURL)

      XCTExpectFailure {
        withSnapshotTesting(record: .failed) {
          assertSnapshot(of: 42, as: .json)
        }
      } issueMatcher: {
        $0.compactDescription.hasPrefix(
          """
          failed - Snapshot does not match reference. A new snapshot was automatically recorded.
          """)
      }

      try XCTAssertEqual(
        String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self),
        "42"
      )
    }
  #endif

  func testRecordFailed_NoFailure() throws {
    try Data("42".utf8).write(to: snapshotURL)
    let modifiedDate =
      try FileManager.default
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

  #if canImport(Darwin)
    func testRecordFailed_MissingFile() throws {
      XCTExpectFailure {
        withSnapshotTesting(record: .failed) {
          assertSnapshot(of: 42, as: .json)
        }
      } issueMatcher: {
        $0.compactDescription.hasPrefix(
          """
          failed - No reference was found on disk. Automatically recorded snapshot: …
          """)
      }

      try XCTAssertEqual(
        String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self),
        "42"
      )
    }
  #endif
}
