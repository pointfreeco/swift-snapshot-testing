import XCTest
import SnapshotTesting

class BaseTestCase: XCTestCase {
  override func invokeTest() {
    withSnapshotTesting(
      record: .failed,
      diffTool: .ksdiff
    ) {
      super.invokeTest()
    }
  }
}
