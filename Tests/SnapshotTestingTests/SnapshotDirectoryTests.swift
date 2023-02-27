import XCTest

@testable import SnapshotTesting

final class SnapshotDirectoryTests: XCTestCase {

  func test_packageSnapshotsAtPath() async throws {
    let fileUrl = URL(string: "/Code/pointfree/swift-snapshot-testing/Tests/SnapshotTestingTests/SnapshotTests.swift")!
    let fileName = "SnapshotTests"
    let path = "/Code/pointfree/snapshots"
    XCTAssertEqual(
      SnapshotDirectory.packageSnapshotsAtPath(path).makeURL(fileUrl: fileUrl, fileName: fileName)?.path,
      "/Code/pointfree/snapshots/SnapshotTestingTests/SnapshotTests"
    )
  }
  func test_packageSnapshotsAtPath_nested() async throws {
    let fileUrl = URL(string: "/Code/pointfree/swift-snapshot-testing/Tests/SnapshotTestingTests/Internal/InternalTests.swift")!
    let fileName = "InternalTests"
    let path = "/Code/pointfree/snapshots"
    XCTAssertEqual(
      SnapshotDirectory.packageSnapshotsAtPath(path).makeURL(fileUrl: fileUrl, fileName: fileName)?.path,
      "/Code/pointfree/snapshots/SnapshotTestingTests/Internal/InternalTests"
    )
  }
  func test_packageSnapshotsAtPath_not_swift_package() async throws {
    let fileUrl = URL(string: "/Code/pointfree/swift-snapshot-testing/NotTests/SnapshotTestingTests/SnapshotTests.swift")!
    let fileName = "InternalTests"
    let path = "/Code/pointfree/snapshots"
    XCTAssertNil(SnapshotDirectory.packageSnapshotsAtPath(path).makeURL(fileUrl: fileUrl, fileName: fileName))
  }

  func test_path() async throws {
    let fileUrl = URL(string: "/Code/pointfree/swift-snapshot-testing/Tests/SnapshotTestingTests/SnapshotTests.swift")!
    let fileName = "SnapshotTests"
    let path = "/Code/pointfree/snapshots"
    XCTAssertEqual(
      SnapshotDirectory.path(path).makeURL(fileUrl: fileUrl, fileName: fileName)?.path,
      "/Code/pointfree/snapshots"
    )
  }
  func test_path_nested() async throws {
    let fileUrl = URL(string: "/Code/pointfree/swift-snapshot-testing/Tests/Internal/InternalTests.swift")!
    let fileName = "InternalTests"
    let path = "/Code/pointfree/snapshots"
    XCTAssertEqual(
      SnapshotDirectory.path(path).makeURL(fileUrl: fileUrl, fileName: fileName)?.path,
      "/Code/pointfree/snapshots"
    )
  }

  func test_snapshotsForFile() async throws {
    let fileUrl = URL(string: "/Code/pointfree/swift-snapshot-testing/Tests/SnapshotTestingTests/SnapshotTests.swift")!
    let fileName = "SnapshotTests"
    XCTAssertEqual(
      SnapshotDirectory.snapshotsForFile.makeURL(fileUrl: fileUrl, fileName: fileName)?.path,
      "/Code/pointfree/swift-snapshot-testing/Tests/SnapshotTestingTests/__Snapshots__/SnapshotTests"
    )
  }
  func test_snapshotsForFile_nested() async throws {
    let fileUrl = URL(string: "/Code/pointfree/swift-snapshot-testing/Tests/SnapshotTestingTests/Internal/InternalTests.swift")!
    let fileName = "InternalTests"
    XCTAssertEqual(
      SnapshotDirectory.snapshotsForFile.makeURL(fileUrl: fileUrl, fileName: fileName)?.path,
      "/Code/pointfree/swift-snapshot-testing/Tests/SnapshotTestingTests/Internal/__Snapshots__/InternalTests"
    )
  }
}
