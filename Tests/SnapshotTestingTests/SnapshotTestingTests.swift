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
    assertSnapshot(of: .any, matching: user)
  }

  func testNamedAssertion() {
    struct User { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
    assertSnapshot(of: .any, matching: user, named: "named")
  }

  func testWithDate() {
    assertSnapshot(of: .any, matching: Date(timeIntervalSinceReferenceDate: 0))
  }

  func testWithEncodable() {
    struct User: Encodable { let id: Int, name: String, bio: String }

    if #available(OSX 10.13, *) {
      assertSnapshot(of: .json, matching: User(id: 1, name: "Blobby", bio: "Blobbed around the world."))
    }
  }

  func testWithNSObject() {
    assertSnapshot(of: .any, matching: NSObject())
  }

  func testMultipleSnapshots() {
    assertSnapshot(of: .any, matching: [1])
    assertSnapshot(of: .any, matching: [1, 2])
  }

  func testUIView() {
    #if os(iOS)
    let view = UIButton(type: .contactAdd)
    assertSnapshot(matching: view)
    assertSnapshot(of: .recursiveDescription, matching: view)
  #endif
  }

  func testNSView() {
    #if os(macOS)
    let button = NSButton()
    button.bezelStyle = .rounded
    button.title = "Push Me"
    button.sizeToFit()
    if #available(macOS 10.14, *) {
      assertSnapshot(matching: button)
      assertSnapshot(of: .recursiveDescription, matching: button)
    }
    #endif
  }

  func testWebView() throws {
    #if os(iOS) || os(macOS)
    let fixtureUrl = URL(fileURLWithPath: String(#file))
      .deletingLastPathComponent()
      .appendingPathComponent("fixture.html")
    let html = try String(contentsOf: fixtureUrl)
    let webView = WKWebView()
    webView.loadHTMLString(html, baseURL: nil)
    if #available(macOS 10.14, *) {
      assertSnapshot(matching: webView, named: platform)
    }
    #endif
  }

  func testPrecision() {
    #if os(iOS) || os(macOS)
    #if os(iOS)
    let label = UILabel()
    label.frame = CGRect(origin: .zero, size: CGSize(width: 43.5, height: 20.5))
    label.text = "Hello"
    label.backgroundColor = .white
    #elseif os(macOS)
    let label = NSTextField()
    label.frame = CGRect(origin: .zero, size: CGSize(width: 37, height: 16))
    label.stringValue = "Hello"
    label.backgroundColor = .white
    label.isBezeled = false
    label.isEditable = false
    #endif
    if #available(macOS 10.14, *) {
      assertSnapshot(of: .view(precision: 0.9), matching: label, named: platform)
    }
    #endif
  }
}

#if os(Linux)
extension SnapshotTestingTests {
  static var allTests : [(String, (SnapshotTestingTests) -> () throws -> Void)] {
    return [
      ("testMultipleSnapshots", testMultipleSnapshots),
      ("testNamedAssertion", testNamedAssertion),
      ("testNSView", testNSView),
      ("testPrecision", testPrecision),
      ("testUIView", testUIView),
      ("testWebView", testWebView),
      ("testWithAny", testWithAny),
      ("testWithDate", testWithDate),
      ("testWithEncodable", testWithEncodable),
      ("testWithNSObject", testWithNSObject),
    ]
  }
}
#endif
