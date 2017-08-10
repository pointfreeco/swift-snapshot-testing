import XCTest
import SnapshotTesting

class SnapshotTestingTests: XCTestCase {
  #if os(iOS)
    func testExample() {
      let view = UIButton(type: .contactAdd)
      assertSnapshot(matching: view)
    }

    func testWithName() {
      let view = UIButton(type: .infoDark)
      assertSnapshot(matching: view, named: "info-dark")
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

  func testWithAny() {
    struct User { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
    assertSnapshot(matching: user)
  }

  func testWithNSObject() {
    assertSnapshot(matching: NSObject())
  }

  func testMultipleSnapshots() {
    assertSnapshot(matching: [1])
    assertSnapshot(matching: [1, 2])
  }
}
