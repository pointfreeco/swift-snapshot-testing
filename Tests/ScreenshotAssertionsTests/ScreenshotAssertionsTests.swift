import XCTest
import ScreenshotAssertions

class ScreenshotAssertionsTests: XCTestCase {
  func testExample() {
    let view = UIButton(type: .contactAdd)
    assertScreenshot(matching: view).map(add)
  }

  func testWithIdentifier() {
    let view = UIButton(type: .infoDark)
    assertScreenshot(matching: view, identifier: "info_dark").map(add)
  }
}
