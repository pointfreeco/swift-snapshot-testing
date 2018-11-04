@testable import SnapshotTesting
import XCTest

#if os(macOS) || os(iOS)
import SceneKit
import SpriteKit
import WebKit

#if os(iOS)
let platform = "ios"
#elseif os(macOS)
let platform = "macos"
extension NSTextField {
  var text: String {
    get { return self.stringValue }
    set { self.stringValue = newValue }
  }
}
#endif
#endif

class SnapshotTestingTests: SnapshotTestCase {
  override func setUp() {
    super.setUp()
    self.diffTool = "ksdiff"
//    record = true
  }

  func testWithAny() {
    struct User { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
    assertSnapshot(of: .any, matching: user)
    assertSnapshot(of: .any, matching: Data("Hello, world!".utf8))
    assertSnapshot(of: .any, matching: URL(string: "https://www.pointfree.co")!)
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
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")

    if #available(macOS 10.13, *) {
      assertSnapshot(of: .json, matching: user)

      #if !os(Linux)
      assertSnapshot(of: .plist, matching: user)
      #endif
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

  func testMixedViews() {
    #if os(macOS) || os(iOS)
    // NB: CircleCI crashes while trying to instantiate SKView
    if #available(macOS 10.14, *) {
      let webView = WKWebView(frame: .init(x: 0, y: 0, width: 50, height: 50))
      webView.loadHTMLString("🌎", baseURL: nil)

      let skView = SKView(frame: .init(x: 50, y: 0, width: 50, height: 50))
      let scene = SKScene(size: .init(width: 50, height: 50))
      let node = SKShapeNode(circleOfRadius: 15)
      node.fillColor = .red
      node.position = .init(x: 25, y: 25)
      scene.addChild(node)
      skView.presentScene(scene)

      let view = View(frame: .init(x: 0, y: 0, width: 100, height: 50))
      view.addSubview(webView)
      view.addSubview(skView)

      assertSnapshot(matching: view, named: platform)
    }
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
      .appendingPathComponent("__Fixtures__/pointfree.html")
    let html = try String(contentsOf: fixtureUrl)
    let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
    webView.loadHTMLString(html, baseURL: nil)
    if #available(macOS 10.14, *) {
      assertSnapshot(matching: webView, named: platform)
    }
    #endif
  }

  func testSCNView() {
    #if os(iOS) || os(macOS)
    // NB: CircleCI crashes while trying to instantiate SCNView
    if #available(macOS 10.14, *) {
      let scene = SCNScene()

      let sphereGeometry = SCNSphere(radius: 3)
      sphereGeometry.segmentCount = 200
      let sphereNode = SCNNode(geometry: sphereGeometry)
      sphereNode.position = SCNVector3Zero
      scene.rootNode.addChildNode(sphereNode)

      sphereGeometry.firstMaterial?.diffuse.contents = URL(fileURLWithPath: String(#file))
        .deletingLastPathComponent()
        .appendingPathComponent("__Fixtures__/earth.png")

      let cameraNode = SCNNode()
      cameraNode.camera = SCNCamera()
      cameraNode.position = SCNVector3Make(0, 0, 8)
      scene.rootNode.addChildNode(cameraNode)

      let omniLight = SCNLight()
      omniLight.type = .omni
      let omniLightNode = SCNNode()
      omniLightNode.light = omniLight
      omniLightNode.position = SCNVector3Make(10, 10, 10)
      scene.rootNode.addChildNode(omniLightNode)

      assertSnapshot(of: .scene(size: .init(width: 500, height: 500)), matching: scene, named: platform)
    }
    #endif
  }

  func testSKView() {
    #if os(macOS) || os(iOS)
    // NB: CircleCI crashes while trying to instantiate SKView
    if #available(macOS 10.14, *) {
      let scene = SKScene(size: .init(width: 50, height: 50))
      let node = SKShapeNode(circleOfRadius: 15)
      node.fillColor = .red
      node.position = .init(x: 25, y: 25)
      scene.addChild(node)

      assertSnapshot(of: .scene(size: .init(width: 50, height: 50)), matching: scene, named: platform)
    }
    #endif
  }

  func testPrecision() {
    #if os(iOS) || os(macOS)
    #if os(iOS)
    let label = UILabel()
    label.frame = CGRect(origin: .zero, size: CGSize(width: 43.5, height: 20.5))
    label.backgroundColor = .white
    #elseif os(macOS)
    let label = NSTextField()
    label.frame = CGRect(origin: .zero, size: CGSize(width: 37, height: 16))
    label.backgroundColor = .white
    label.isBezeled = false
    label.isEditable = false
    #endif
    if #available(macOS 10.14, *) {
      label.text = "Hello."
      assertSnapshot(of: .view(precision: 0.9), matching: label, named: platform)
      label.text = "Hello"
      assertSnapshot(of: .view(precision: 0.9), matching: label, named: platform)
    }
    #endif
  }
}

#if os(Linux)
extension SnapshotTestingTests {
  static var allTests : [(String, (SnapshotTestingTests) -> () throws -> Void)] {
    return [
      ("testMixedViews", testMixedViews),
      ("testMultipleSnapshots", testMultipleSnapshots),
      ("testNamedAssertion", testNamedAssertion),
      ("testNSView", testNSView),
      ("testPrecision", testPrecision),
      ("testSCNView", testSCNView),
      ("testSKView", testSKView),
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
