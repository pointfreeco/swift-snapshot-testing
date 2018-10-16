@testable import SnapshotTesting
import XCTest

#if os(iOS)
import WebKit
let platform = "ios"
#elseif os(macOS)
import WebKit
let platform = "macos"
#endif

class SnapshotTestingTests: SnapshotTestCase {
  override func setUp() {
    super.setUp()
//    record = true
  }

  func testWithAny() {
    struct User { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
    assertSnapshot(matchingAny: user)
  }

  func testNamedAssertion() {
    struct User { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
    assertSnapshot(matchingAny: user, named: "named")
  }

  #if os(iOS)
  func testUIView() {
    let view = UIButton(type: .contactAdd)
    assertSnapshot(matching: view)
  }
  #endif

  #if os(macOS)
  func testNSView() {
    let button = NSButton()
    button.bezelStyle = .rounded
    button.title = "Push Me"
    button.sizeToFit()
    if #available(macOS 10.14, *) {
      assertSnapshot(matching: button)
    }
  }
  #endif

  func testWithDate() {
    assertSnapshot(matchingAny: Date(timeIntervalSinceReferenceDate: 0))
  }

  func testWithNSObject() {
    assertSnapshot(matchingAny: NSObject())
  }

  func testMultipleSnapshots() {
    assertSnapshot(matchingAny: [1])
    assertSnapshot(matchingAny: [1, 2])
  }

  #if os(iOS) || os(macOS)
  func testWebView() throws {
    let fixtureUrl = URL(fileURLWithPath: String(#file))
      .deletingLastPathComponent()
      .appendingPathComponent("fixture.html")
    let html = try String(contentsOf: fixtureUrl)

    let webView = WKWebView()
    webView.loadHTMLString(html, baseURL: nil)
    if #available(macOS 10.14, *) {
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
      ("testNamedAssertion", testNamedAssertion),
      ("testWithDate", testWithDate),
      ("testWithNSObject", testWithNSObject),
      ("testMultipleSnapshots", testMultipleSnapshots),
    ]
  }
}
#endif
