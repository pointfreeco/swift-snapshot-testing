import XCTest
import SnapshotAssertion

class SnapshotAssertionTests: XCTestCase {
  func testExample() {
    let view = UIButton(type: .contactAdd)
    assertSnapshot(matching: view).map(add)
  }

  func testWithIdentifier() {
    let view = UIButton(type: .infoDark)
    assertSnapshot(matching: view, identifier: "info_dark").map(add)
  }
}
