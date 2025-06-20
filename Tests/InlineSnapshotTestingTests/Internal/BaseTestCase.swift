import SnapshotTesting
import XCTest

class BaseTestCase: XCTestCase {
  override func invokeTest() {
    withTestingEnvironment(
      record: .failed,
      diffTool: .ksdiff
    ) {
      super.invokeTest()
    }
  }
}
