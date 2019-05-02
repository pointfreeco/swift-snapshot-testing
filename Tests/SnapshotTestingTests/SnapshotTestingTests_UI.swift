@testable import SnapshotTesting
import XCTest

class SnapshotTestingTests_UI: XCTestCase {

  var app: XCUIApplication!
  
  override func setUp() {
    super.setUp()
    diffTool = "ksdiff"
    continueAfterFailure = false

    app = XCUIApplication()
    app.launch()
  }

  override func tearDown() {
    record = false
    super.tearDown()
  }
  
  func testXCUIElement() {
    let element = app.otherElements["testView1"]
    
    assertSnapshot(matching: element, as: .recursiveDescription)
  }

}
