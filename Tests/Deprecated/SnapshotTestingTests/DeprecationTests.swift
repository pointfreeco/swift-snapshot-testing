import SnapshotTesting
import XCTest

final class DeprecationTests: XCTestCase {
  @available(*, deprecated)
  func testIsRecordingProxy() {
    SnapshotTesting.record = true
    XCTAssertEqual(isRecording, true)

    SnapshotTesting.record = false
    XCTAssertEqual(isRecording, false)
  }
}
