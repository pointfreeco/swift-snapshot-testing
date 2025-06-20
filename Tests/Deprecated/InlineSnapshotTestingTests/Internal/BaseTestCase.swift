import SnapshotTesting
import XCTest

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
