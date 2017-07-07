import XCTest
import ScreenshotAssertions

class ScreenshotAssertionsTests: XCTestCase {
  func testExample() {
    let view = UIButton(type: .contactAdd)
    assertScreenshot(matching: view)
  }
}
