import XCTSnapshot
import XCTest

@MainActor
class BaseTestCase: XCTestCase, Sendable {
  override func invokeTest() {
    withTestingEnvironment(
      record: .failed,
      diffTool: .ksdiff,
      platform: ""
    ) {
      super.invokeTest()
    }
  }
}
