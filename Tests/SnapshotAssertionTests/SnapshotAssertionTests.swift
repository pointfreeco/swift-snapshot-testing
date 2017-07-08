import XCTest
import SnapshotAssertion

class SnapshotAssertionTests: XCTestCase {
  func testExample() {
    let view = UIButton(type: .contactAdd)
    assertSnapshot(matching: view)
  }

  func testWithIdentifier() {
    let view = UIButton(type: .infoDark)
    assertSnapshot(matching: view, identifier: "info_dark")
  }

  func testWithString() {
    assertSnapshot(matching: "Hello, world!")
  }
}
