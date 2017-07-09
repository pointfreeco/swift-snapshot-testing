import XCTest
import SnapshotAssertion

class SnapshotAssertionTests: XCTestCase {
  #if os(iOS)
    func testExample() {
      let view = UIButton(type: .contactAdd)
      assertSnapshot(matching: view)
    }

    func testWithIdentifier() {
      let view = UIButton(type: .infoDark)
      assertSnapshot(matching: view, identifier: "info_dark")
    }
  #endif

  #if os(macOS)
    func testCocoa() {
      let button = NSButton()
      button.bezelStyle = .rounded
      button.title = "Push Me"
      button.sizeToFit()
      assertSnapshot(matching: button)
    }
  #endif

  func testWithString() {
    struct User: Encodable {
      let id: Int
      let name: String
    }
    assertSnapshot(encoding: User(id: 1, name: "Blob"))
  }
}
