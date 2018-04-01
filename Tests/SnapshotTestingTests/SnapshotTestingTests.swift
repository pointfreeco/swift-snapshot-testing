import SnapshotTesting
import XCTest

#if os(iOS)
import WebKit
let platform = "ios"
#elseif os(macOS)
import WebKit
let platform = "macos"
#endif

class SnapshotTestingTests: XCTestCase {
  override func setUp() {
    super.setUp()
//    record = true
  }

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

  #if os(iOS) || os(macOS)
  func testWebView() throws {
    let fixtureUrl = URL(fileURLWithPath: String(#file))
      .deletingLastPathComponent()
      .appendingPathComponent("fixture.html")
    let html = try String(contentsOf: fixtureUrl)

    let webView = WKWebView()
    webView.loadHTMLString(html, baseURL: nil)
    if #available(macOS 10.13, *) {
      assertSnapshot(matching: webView, named: platform)
    }
  }
  #endif
}

#if os(Linux)
extension SnapshotTestingTests {
  static var allTests : [(String, (SnapshotTestingTests) -> () throws -> Void)] {
    return [
      ("testWithAny", testWithAny),
      ("testWithNSObject", testWithNSObject),
      ("testMultipleSnapshots", testMultipleSnapshots),
    ]
  }
}
#endif
