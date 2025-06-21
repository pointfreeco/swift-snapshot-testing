@preconcurrency import Foundation
@preconcurrency import XCTest

@testable import XCTSnapshot

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(SceneKit)
import SceneKit
#endif
#if canImport(SpriteKit)
import SpriteKit
@preconcurrency import SwiftUI
#endif
#if canImport(WebKit)
@preconcurrency import WebKit
#endif
#if canImport(UIKit)
import UIKit.UIView
#endif

#if os(macOS)
@preconcurrency import AppKit
#endif

@MainActor
final class SnapshotTestingTests: BaseTestCase {

  @available(macOS 10.13, tvOS 11.0, *)
  func testAnyAsJson() throws {
    struct User: Encodable { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")

    let data = try JSONEncoder().encode(user)
    let any = try JSONSerialization.jsonObject(with: data, options: [])

    try assert(of: any, as: .json)
  }

  @MainActor
  func testAutolayout() async throws {
#if os(iOS)
    let vc = UIViewController()
    vc.view.translatesAutoresizingMaskIntoConstraints = false
    let subview = UIView()
    subview.translatesAutoresizingMaskIntoConstraints = false
    vc.view.addSubview(subview)
    NSLayoutConstraint.activate([
      subview.topAnchor.constraint(equalTo: vc.view.topAnchor),
      subview.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor),
      subview.leftAnchor.constraint(equalTo: vc.view.leftAnchor),
      subview.rightAnchor.constraint(equalTo: vc.view.rightAnchor),
    ])
    try await assert(of: vc, as: .image)
#endif
  }

  func testCaseIterable() throws {
    enum Direction: String, CaseIterable {
      case up, down, left, right
      var rotatedLeft: Direction {
        switch self {
        case .up: return .left
        case .down: return .right
        case .left: return .down
        case .right: return .up
        }
      }
    }

    try assert(
      of: { $0.rotatedLeft },
      as: SyncSnapshot<Direction, StringBytes>.func(into: .description)
    )
  }

  func testCGPath() throws {
#if os(iOS) || os(tvOS) || os(macOS)
    let path = CGPath.heart

    let osName: String
#if os(iOS)
    osName = "iOS"
#elseif os(tvOS)
    osName = "tvOS"
#elseif os(macOS)
    osName = "macOS"
#endif

    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
      try assert(of: path, as: .image, named: osName)
    }

    if #available(iOS 11.0, OSX 10.13, tvOS 11.0, *) {
      try assert(of: path, as: .elementsDescription, named: osName)
    }
#endif
  }

  func testData() async throws {
    let data = Data([0xDE, 0xAD, 0xBE, 0xEF])

    try assert(of: data, as: .data)
  }

  func testEncodable() throws {
    struct User: Encodable { let id: Int, name: String, bio: String }
    let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")

    if #available(iOS 11.0, macOS 10.13, tvOS 11.0, *) {
      try assert(of: user, as: .json)
    }
    try assert(of: user, as: .plist)
  }

  func testMixedViews() {
    //    #if os(iOS) || os(macOS)
    //    // NB: CircleCI crashes while trying to instantiate SKView.
    //    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
    //      let webView = WKWebView(frame: .init(x: 0, y: 0, width: 50, height: 50))
    //      webView.loadHTMLString("🌎", baseURL: nil)
    //
    //      let skView = SKView(frame: .init(x: 50, y: 0, width: 50, height: 50))
    //      let scene = SKScene(size: .init(width: 50, height: 50))
    //      let node = SKShapeNode(circleOfRadius: 15)
    //      node.fillColor = .red
    //      node.position = .init(x: 25, y: 25)
    //      scene.addChild(node)
    //      skView.presentScene(scene)
    //
    //      let view = View(frame: .init(x: 0, y: 0, width: 100, height: 50))
    //      view.addSubview(webView)
    //      view.addSubview(skView)
    //
    //     try await assert(of: view, as: .image, named: platform)
    //    }
    //    #endif
  }

  func testNSBezierPath() async throws {
#if os(macOS)
    let path = NSBezierPath.heart

    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
      try assert(of: path, as: .image, named: "macOS")
    }

    try assert(of: path, as: .elementsDescription, named: "macOS")
#endif
  }

  @MainActor
  func testNSView() async throws {
#if os(macOS)
    let button = NSButton()
    button.bezelStyle = .rounded
    button.title = "Push Me"
    button.sizeToFit()
    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
      try await assert(of: button, as: .image, record: .all)
      print("Finished")
      try await assert(of: button, as: .recursiveDescription)
    }
    print("Finished")
#endif
  }

  @MainActor
  func testNSViewWithLayer() async throws {
#if os(macOS)
    let view = NSView()
    view.frame = CGRect(x: 0.0, y: 0.0, width: 10.0, height: 10.0)
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.green.cgColor
    view.layer?.cornerRadius = 5
    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
      try await assert(of: view, as: .image)
      try await assert(of: view, as: .recursiveDescription)
    }
#endif
  }

  @MainActor
  func testPrecision() async throws {
#if os(iOS) || os(macOS) || os(tvOS)
#if os(iOS) || os(tvOS)
    let label = UILabel()
#if os(iOS)
    label.frame = CGRect(origin: .zero, size: CGSize(width: 43.5, height: 20.5))
#elseif os(tvOS)
    label.frame = CGRect(origin: .zero, size: CGSize(width: 98, height: 46))
#endif
    label.backgroundColor = .white
#elseif os(macOS)
    let label = NSTextField()
    label.frame = CGRect(origin: .zero, size: CGSize(width: 37, height: 16))
    label.backgroundColor = .white
    label.isBezeled = false
    label.isEditable = false
#endif
    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
      label.text = "Hello."
      try await assert(of: label, as: .image(precision: 0.9), named: platform + ".1")
      label.text = "Hello"
      try await assert(of: label, as: .image(precision: 0.9), named: platform + ".2")
    }
#endif
  }

  func testImagePrecision() throws {
#if os(iOS) || os(tvOS) || os(macOS)
    let imageURL = URL(fileURLWithPath: #filePath, isDirectory: false)
      .deletingLastPathComponent()
      .appendingPathComponent("__Fixtures__/testImagePrecision.reference.png")
#if os(iOS) || os(tvOS)
    let image = try XCTUnwrap(UIImage(contentsOfFile: imageURL.path))
#elseif os(macOS)
    let image = try XCTUnwrap(NSImage(byReferencing: imageURL))
#endif

    try assert(of: image, as: .image(precision: 0.995), named: "exact")
    if #available(iOS 11.0, tvOS 11.0, macOS 10.13, *) {
      try assert(of: image, as: .image(perceptualPrecision: 0.98), named: "perceptual")
    }
#endif
  }

#if compiler(>=6.1)
  func testSCNView() async throws {
#if os(iOS) || os(macOS) || os(tvOS)
    // NB: CircleCI crashes while trying to instantiate SCNView.
    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
      @MainActor
      class Scene: SCNScene, Sendable {}
      let scene = Scene()

      let sphereGeometry = SCNSphere(radius: 3)
      sphereGeometry.segmentCount = 200
      let sphereNode = SCNNode(geometry: sphereGeometry)
      sphereNode.position = SCNVector3Zero
      scene.rootNode.addChildNode(sphereNode)

      sphereGeometry.firstMaterial?.diffuse.contents = URL(fileURLWithPath: #filePath, isDirectory: false)
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

      try await assert(
        of: scene,
        as: .image(size: .init(width: 500, height: 500)),
        named: platform
      )
    }
#endif
  }
  #endif

#if compiler(>=6.1)
  func testSKView() async throws {
#if os(iOS) || os(macOS) || os(tvOS)
    @MainActor
    class Scene: SKScene, Sendable {}
    // NB: CircleCI crashes while trying to instantiate SKView.
    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
      let scene = Scene(size: .init(width: 50, height: 50))
      let node = SKShapeNode(circleOfRadius: 15)
      node.fillColor = .red
      node.position = .init(x: 25, y: 25)
      scene.addChild(node)

      try await assert(
        of: scene,
        as: .image(size: .init(width: 50, height: 50)),
        named: platform
      )
    }
#endif
  }
  #endif

  @MainActor
  func testTableViewController() async throws {
#if os(iOS)
    class TableViewController: UITableViewController {
      override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
      }
      override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
      {
        return 10
      }
      override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
      -> UITableViewCell
      {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
      }
    }
    try await assert(
      of: await TableViewController(),
      as: .image(layout: .device(.iPhoneSE))
    )
#endif
  }

  @MainActor
  func testAssertMultipleSnapshot() async throws {
#if os(iOS)
    class TableViewController: UITableViewController {
      override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
      }

      override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
      ) -> Int {
        return 10
      }

      override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
      ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
      }

      override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        tableView.reloadData()
      }
    }

    try await assert(
      of: await TableViewController(),
      as: [
        "iPad-image": .image(layout: .device(.iPadMini8_3)),
        "iPhoneSe-image": .image(layout: .device(.iPhoneSE)),
      ]
    )
    try await assert(
      of: await TableViewController(),
      as: [.image(layout: .device(.iPhoneX)), .image(layout: .device(.iPhoneXSMax))]
    )
#endif
  }

  @MainActor
  func testTraits() async throws {
#if os(iOS) || os(tvOS)
    if #available(iOS 11.0, tvOS 11.0, *) {
      class MyViewController: UIViewController {
        let topLabel = UILabel()
        let leadingLabel = UILabel()
        let trailingLabel = UILabel()
        let bottomLabel = UILabel()

        override func viewDidLoad() {
          super.viewDidLoad()

          self.navigationItem.leftBarButtonItem = .init(
            barButtonSystemItem: .add, target: nil, action: nil)

          self.view.backgroundColor = .white

          self.topLabel.text = "What's"
          self.leadingLabel.text = "the"
          self.trailingLabel.text = "point"
          self.bottomLabel.text = "?"

          self.topLabel.translatesAutoresizingMaskIntoConstraints = false
          self.leadingLabel.translatesAutoresizingMaskIntoConstraints = false
          self.trailingLabel.translatesAutoresizingMaskIntoConstraints = false
          self.bottomLabel.translatesAutoresizingMaskIntoConstraints = false

          self.view.addSubview(self.topLabel)
          self.view.addSubview(self.leadingLabel)
          self.view.addSubview(self.trailingLabel)
          self.view.addSubview(self.bottomLabel)

          NSLayoutConstraint.activate([
            self.topLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.topLabel.centerXAnchor.constraint(
              equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
            self.leadingLabel.leadingAnchor.constraint(
              equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            self.leadingLabel.trailingAnchor.constraint(
              lessThanOrEqualTo: self.view.safeAreaLayoutGuide.centerXAnchor),
            //            self.leadingLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
            self.leadingLabel.centerYAnchor.constraint(
              equalTo: self.view.safeAreaLayoutGuide.centerYAnchor),
            self.trailingLabel.leadingAnchor.constraint(
              greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.centerXAnchor),
            self.trailingLabel.trailingAnchor.constraint(
              equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            self.trailingLabel.centerYAnchor.constraint(
              equalTo: self.view.safeAreaLayoutGuide.centerYAnchor),
            self.bottomLabel.bottomAnchor.constraint(
              equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            self.bottomLabel.centerXAnchor.constraint(
              equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
          ])
        }

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
          super.traitCollectionDidChange(previousTraitCollection)
          self.topLabel.font = .preferredFont(
            forTextStyle: .headline, compatibleWith: self.traitCollection)
          self.leadingLabel.font = .preferredFont(
            forTextStyle: .body, compatibleWith: self.traitCollection)
          self.trailingLabel.font = .preferredFont(
            forTextStyle: .body, compatibleWith: self.traitCollection)
          self.bottomLabel.font = .preferredFont(
            forTextStyle: .subheadline, compatibleWith: self.traitCollection)
          self.view.setNeedsUpdateConstraints()
          self.view.updateConstraintsIfNeeded()
        }
      }

#if os(iOS)
      try await assert(of: await MyViewController(), as: .image(layout: .device(.iPhoneSE)), named: "iphone-se")
      try await assert(of: await MyViewController(), as: .image(layout: .device(.iPhone8)), named: "iphone-8")
      try await assert(of: await MyViewController(), as: .image(layout: .device(.iPhone8Plus)), named: "iphone-8-plus")
      try await assert(of: await MyViewController(), as: .image(layout: .device(.iPhoneX)), named: "iphone-x")
      try await assert(of: await MyViewController(), as: .image(layout: .device(.iPhoneXR)), named: "iphone-xr")
      try await assert(of: await MyViewController(), as: .image(layout: .device(.iPhoneXSMax)), named: "iphone-xs-max")
      try await assert(of: await MyViewController(), as: .image(layout: .device(.iPadMini8_3)), named: "ipad-mini")
      try await assert(of: await MyViewController(), as: .image(layout: .device(.iPad9_7)), named: "ipad-9-7")
      try await assert(of: await MyViewController(), as: .image(layout: .device(.iPad10_2)), named: "ipad-10-2")
      try await assert(of: await MyViewController(), as: .image(layout: .device(.iPadPro10_5)), named: "ipad-pro-10-5")
      try await assert(of: await MyViewController(), as: .image(layout: .device(.iPadPro11)), named: "ipad-pro-11")
      try await assert(of: await MyViewController(), as: .image(layout: .device(.iPadPro12_9)), named: "ipad-pro-12-9")

      try await assert(
        of: await MyViewController(),
        as: .recursiveDescription(layout: .device(.iPhoneSE)),
        named: "iphone-se"
      )
      try await assert(
        of: await MyViewController(),
        as: .recursiveDescription(layout: .device(.iPhone8)),
        named: "iphone-8"
      )
      try await assert(
        of: await MyViewController(),
        as: .recursiveDescription(layout: .device(.iPhone8Plus)),
        named: "iphone-8-plus"
      )
      try await assert(
        of: await MyViewController(),
        as: .recursiveDescription(layout: .device(.iPhoneX)),
        named: "iphone-x"
      )
      try await assert(
        of: await MyViewController(),
        as: .recursiveDescription(layout: .device(.iPhoneXR)),
        named: "iphone-xr"
      )
      try await assert(
        of: await MyViewController(),
        as: .recursiveDescription(layout: .device(.iPhoneXSMax)),
        named: "iphone-xs-max"
      )
      try await assert(
        of: await MyViewController(),
        as: .recursiveDescription(layout: .device(.iPadMini8_3)),
        named: "ipad-mini"
      )
      try await assert(
        of: await MyViewController(),
        as: .recursiveDescription(layout: .device(.iPad9_7)),
        named: "ipad-9-7"
      )
      try await assert(
        of: await MyViewController(),
        as: .recursiveDescription(layout: .device(.iPad10_2)),
        named: "ipad-10-2"
      )
      try await assert(
        of: await MyViewController(),
        as: .recursiveDescription(layout: .device(.iPadPro10_5)),
        named: "ipad-pro-10-5"
      )
      try await assert(
        of: await MyViewController(),
        as: .recursiveDescription(layout: .device(.iPadPro11)),
        named: "ipad-pro-11"
      )
      try await assert(
        of: await MyViewController(),
        as: .recursiveDescription(layout: .device(.iPadPro12_9)),
        named: "ipad-pro-12-9"
      )

      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPhoneSE(.portrait))),
        named: "iphone-se"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPhone8(.portrait))),
        named: "iphone-8"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPhone8Plus(.portrait))),
        named: "iphone-8-plus"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPhoneX(.portrait))),
        named: "iphone-x"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPhoneXR(.portrait))),
        named: "iphone-xr"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPhoneXSMax(.portrait))),
        named: "iphone-xs-max"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadMini8_3(.landscape))),
        named: "ipad-mini"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPad9_7(.landscape))),
        named: "ipad-9-7"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPad10_2(.landscape))),
        named: "ipad-10-2"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadPro10_5(.landscape))),
        named: "ipad-pro-10-5"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadPro11(.landscape))),
        named: "ipad-pro-11"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadPro12_9(.landscape))),
        named: "ipad-pro-12-9"
      )

      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadMini8_3(.landscape(.compact)))),
        named: "ipad-mini-33-split-landscape"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadMini8_3(.landscape(.medium)))),
        named: "ipad-mini-50-split-landscape"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadMini8_3(.landscape(.regular)))),
        named: "ipad-mini-66-split-landscape"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadMini8_3(.portrait(.compact)))),
        named: "ipad-mini-33-split-portrait"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadMini8_3(.portrait(.regular)))),
        named: "ipad-mini-66-split-portrait"
      )

      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPad9_7(.landscape(.compact)))),
        named: "ipad-9-7-33-split-landscape"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPad9_7(.landscape(.medium)))),
        named: "ipad-9-7-50-split-landscape"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPad9_7(.landscape(.regular)))),
        named: "ipad-9-7-66-split-landscape"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPad9_7(.portrait(.compact)))),
        named: "ipad-9-7-33-split-portrait"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPad9_7(.portrait(.regular)))),
        named: "ipad-9-7-66-split-portrait"
      )

      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPad10_2(.landscape(.compact)))),
        named: "ipad-10-2-split-landscape"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPad10_2(.landscape(.medium)))),
        named: "ipad-10-2-50-split-landscape"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPad10_2(.landscape(.regular)))),
        named: "ipad-10-2-66-split-landscape"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPad10_2(.portrait(.compact)))),
        named: "ipad-10-2-33-split-portrait"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPad10_2(.portrait(.regular)))),
        named: "ipad-10-2-66-split-portrait"
      )

      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadPro10_5(.landscape(.compact)))),
        named: "ipad-pro-10inch-33-split-landscape"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadPro10_5(.landscape(.medium)))),
        named: "ipad-pro-10inch-50-split-landscape"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadPro10_5(.landscape(.regular)))),
        named: "ipad-pro-10inch-66-split-landscape"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadPro10_5(.portrait(.compact)))),
        named: "ipad-pro-10inch-33-split-portrait"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadPro10_5(.portrait(.regular)))),
        named: "ipad-pro-10inch-66-split-portrait"
      )

      try await assert(
        of: await MyViewController(), as: .image(layout: .device(.iPadPro11(.landscape(.compact)))),
        named: "ipad-pro-11inch-33-split-landscape")
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadPro11(.landscape(.medium)))),
        named: "ipad-pro-11inch-50-split-landscape"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadPro11(.landscape(.regular)))),
        named: "ipad-pro-11inch-66-split-landscape"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadPro11(.portrait(.compact)))),
        named: "ipad-pro-11inch-33-split-portrait"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadPro11(.portrait(.regular)))),
        named: "ipad-pro-11inch-66-split-portrait"
      )

      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadPro12_9(.landscape(.compact)))),
        named: "ipad-pro-12inch-33-split-landscape"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadPro12_9(.landscape(.medium)))),
        named: "ipad-pro-12inch-50-split-landscape"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadPro12_9(.landscape(.regular)))),
        named: "ipad-pro-12inch-66-split-landscape"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadPro12_9(.portrait(.compact)))),
        named: "ipad-pro-12inch-33-split-portrait"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadPro12_9(.portrait(.regular)))),
        named: "ipad-pro-12inch-66-split-portrait"
      )

      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPhoneSE(.landscape))),
        named: "iphone-se-alternative"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPhone8(.landscape))),
        named: "iphone-8-alternative"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPhone8Plus(.landscape))),
        named: "iphone-8-plus-alternative"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPhoneX(.landscape))),
        named: "iphone-x-alternative"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPhoneXR(.landscape))),
        named: "iphone-xr-alternative"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPhoneXSMax(.landscape))),
        named: "iphone-xs-max-alternative"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadMini8_3(.portrait))),
        named: "ipad-mini-alternative"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPad9_7(.portrait))),
        named: "ipad-9-7-alternative"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPad10_2(.portrait))),
        named: "ipad-10-2-alternative"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadPro10_5(.portrait))),
        named: "ipad-pro-10-5-alternative"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadPro11(.portrait))),
        named: "ipad-pro-11-alternative"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.iPadPro12_9(.portrait))),
        named: "ipad-pro-12-9-alternative"
      )

      for (name, contentSize) in allContentSizes {
        try await assert(
          of: await MyViewController(),
          as: .image(layout: .device(.iPhoneSE), traits: .init(preferredContentSizeCategory: contentSize)),
          named: "iphone-se-\(name)"
        )
      }
#elseif os(tvOS)
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.tv)),
        named: "tv"
      )
      try await assert(
        of: await MyViewController(),
        as: .image(layout: .device(.tv4K)),
        named: "tv4k"
      )
#endif
    }
#endif
  }

  @MainActor
  func testTraitsEmbeddedInTabNavigation() async throws {
#if os(iOS)
      if #available(iOS 11.0, *) {
        class MyViewController: UIViewController {
          let topLabel = UILabel()
          let leadingLabel = UILabel()
          let trailingLabel = UILabel()
          let bottomLabel = UILabel()

          override func viewDidLoad() {
            super.viewDidLoad()

            let safeAreaView = UIView()
            safeAreaView.backgroundColor = .green
            safeAreaView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(safeAreaView)

            NSLayoutConstraint.activate([
              safeAreaView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
              safeAreaView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
              safeAreaView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
              safeAreaView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])

            self.navigationItem.leftBarButtonItem = .init(
              barButtonSystemItem: .add,
              target: nil,
              action: nil
            )

            self.view.backgroundColor = .yellow

            topLabel.text = "What's"
            leadingLabel.text = "the"
            trailingLabel.text = "point"
            bottomLabel.text = "?"

            [topLabel, leadingLabel, trailingLabel, bottomLabel].forEach {
              $0.translatesAutoresizingMaskIntoConstraints = false
              view.addSubview($0)

              $0.setContentHuggingPriority(.required, for: .vertical)
              $0.setContentHuggingPriority(.required, for: .horizontal)
//              $0.backgroundColor = .white
            }

            NSLayoutConstraint.activate([
              topLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
              topLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),

              leadingLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
              leadingLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.centerXAnchor),
              leadingLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),

              trailingLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.centerXAnchor),
              trailingLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
              trailingLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),

              bottomLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
              bottomLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            ])
          }

          override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            self.topLabel.font = .preferredFont(
              forTextStyle: .headline, compatibleWith: self.traitCollection)
            self.leadingLabel.font = .preferredFont(
              forTextStyle: .body, compatibleWith: self.traitCollection)
            self.trailingLabel.font = .preferredFont(
              forTextStyle: .body, compatibleWith: self.traitCollection)
            self.bottomLabel.font = .preferredFont(
              forTextStyle: .subheadline, compatibleWith: self.traitCollection)
            self.view.setNeedsUpdateConstraints()
            self.view.updateConstraintsIfNeeded()
          }
        }

        class NoRecycleViewController: UIViewController {

          override func viewDidLoad() {
            super.viewDidLoad()

            let myViewController = MyViewController()
            let navController = UINavigationController(rootViewController: myViewController)
            let tabViewController = UITabBarController()
            tabViewController.setViewControllers([navController], animated: false)

            let viewController = self
            viewController.addChild(tabViewController)
            tabViewController.view.translatesAutoresizingMaskIntoConstraints = false
            viewController.view.addSubview(tabViewController.view)
            tabViewController.didMove(toParent: viewController)

            NSLayoutConstraint.activate([
              tabViewController.view.topAnchor.constraint(equalTo: viewController.view.topAnchor),
              tabViewController.view.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
              tabViewController.view.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
              tabViewController.view.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
            ])

            navController.navigationBar.isTranslucent = false
            navController.navigationBar.tintColor = .red
            navController.navigationBar.backgroundColor = .red
            navController.navigationBar.barTintColor = .red
            navController.view.backgroundColor = .blue
          }
        }

        try await assert(of: await NoRecycleViewController(), as: .image(layout: .device(.iPhoneSE)), named: "iphone-se")
        try await assert(of: await NoRecycleViewController(), as: .image(layout: .device(.iPhone8)), named: "iphone-8")
        try await assert(of: await NoRecycleViewController(), as: .image(layout: .device(.iPhone8Plus)), named: "iphone-8-plus")
        try await assert(of: await NoRecycleViewController(), as: .image(layout: .device(.iPhoneX)), named: "iphone-x")
        try await assert(of: await NoRecycleViewController(), as: .image(layout: .device(.iPhoneXR)), named: "iphone-xr")
        try await assert(of: await NoRecycleViewController(), as: .image(layout: .device(.iPhoneXSMax)), named: "iphone-xs-max")
        try await assert(of: await NoRecycleViewController(), as: .image(layout: .device(.iPadMini8_3)), named: "ipad-mini")
        try await assert(of: await NoRecycleViewController(), as: .image(layout: .device(.iPad9_7)), named: "ipad-9-7")
        try await assert(of: await NoRecycleViewController(), as: .image(layout: .device(.iPad10_2)), named: "ipad-10-2")
        try await assert(of: await NoRecycleViewController(), as: .image(layout: .device(.iPadPro10_5)), named: "ipad-pro-10-5")
        try await assert(of: await NoRecycleViewController(), as: .image(layout: .device(.iPadPro11)), named: "ipad-pro-11")
        try await assert(of: await NoRecycleViewController(), as: .image(layout: .device(.iPadPro12_9)), named: "ipad-pro-12-9")

        try await withTestingEnvironment(record: .never) {
          try await assert(of: await NoRecycleViewController(), as: .image(layout: .device(.iPhoneSE(.portrait))), named: "iphone-se")
          try await assert(of: await NoRecycleViewController(), as: .image(layout: .device(.iPhone8(.portrait))), named: "iphone-8")
          try await assert(
            of: await NoRecycleViewController(), as: .image(layout: .device(.iPhone8Plus(.portrait))), named: "iphone-8-plus")
          try await assert(of: await NoRecycleViewController(), as: .image(layout: .device(.iPhoneX(.portrait))), named: "iphone-x")
          try await assert(of: await NoRecycleViewController(), as: .image(layout: .device(.iPhoneXR(.portrait))), named: "iphone-xr")
          try await assert(
            of: await NoRecycleViewController(), as: .image(layout: .device(.iPhoneXSMax(.portrait))), named: "iphone-xs-max")
          try await assert(
            of: await NoRecycleViewController(), as: .image(layout: .device(.iPadMini8_3(.landscape))), named: "ipad-mini")
          try await assert(of: await NoRecycleViewController(), as: .image(layout: .device(.iPad9_7(.landscape))), named: "ipad-9-7")
          try await assert(
            of: await NoRecycleViewController(), as: .image(layout: .device(.iPad10_2(.landscape))), named: "ipad-10-2")
          try await assert(
            of: await NoRecycleViewController(), as: .image(layout: .device(.iPadPro10_5(.landscape))), named: "ipad-pro-10-5")
          try await assert(
            of: await NoRecycleViewController(), as: .image(layout: .device(.iPadPro11(.landscape))), named: "ipad-pro-11")
          try await assert(
            of: await NoRecycleViewController(), as: .image(layout: .device(.iPadPro12_9(.landscape))), named: "ipad-pro-12-9")
        }

        try await assert(
          of: await NoRecycleViewController(), as: .image(layout: .device(.iPhoneSE(.landscape))), named: "iphone-se-alternative")
        try await assert(
          of: await NoRecycleViewController(), as: .image(layout: .device(.iPhone8(.landscape))), named: "iphone-8-alternative")
        try await assert(
          of: await NoRecycleViewController(), as: .image(layout: .device(.iPhone8Plus(.landscape))),
          named: "iphone-8-plus-alternative")
        try await assert(
          of: await NoRecycleViewController(), as: .image(layout: .device(.iPhoneX(.landscape))), named: "iphone-x-alternative")
        try await assert(
          of: await NoRecycleViewController(), as: .image(layout: .device(.iPhoneXR(.landscape))), named: "iphone-xr-alternative")
        try await assert(
          of: await NoRecycleViewController(), as: .image(layout: .device(.iPhoneXSMax(.landscape))),
          named: "iphone-xs-max-alternative")
        try await assert(
          of: await NoRecycleViewController(), as: .image(layout: .device(.iPadMini8_3(.portrait))), named: "ipad-mini-alternative")
        try await assert(
          of: await NoRecycleViewController(), as: .image(layout: .device(.iPad9_7(.portrait))), named: "ipad-9-7-alternative")
        try await assert(
          of: await NoRecycleViewController(), as: .image(layout: .device(.iPad10_2(.portrait))), named: "ipad-10-2-alternative")
        try await assert(
          of: await NoRecycleViewController(), as: .image(layout: .device(.iPadPro10_5(.portrait))),
          named: "ipad-pro-10-5-alternative")
        try await assert(
          of: await NoRecycleViewController(), as: .image(layout: .device(.iPadPro11(.portrait))),
          named: "ipad-pro-11-alternative")
        try await assert(
          of: await NoRecycleViewController(), as: .image(layout: .device(.iPadPro12_9(.portrait))),
          named: "ipad-pro-12-9-alternative")
      }
#endif
  }

  @MainActor
  func testCollectionViewsWithMultipleScreenSizes() async throws {
#if os(iOS)
    final class CollectionViewController: UIViewController, UICollectionViewDataSource,
                                          UICollectionViewDelegateFlowLayout
    {

      let flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 20
        return layout
      }()

      lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)

      override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        view.addSubview(collectionView)

        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
          collectionView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
          collectionView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
          collectionView.trailingAnchor.constraint(
            equalTo: view.layoutMarginsGuide.trailingAnchor),
          collectionView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
        ])

        collectionView.reloadData()
      }

      override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
      }

      override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        collectionView.collectionViewLayout.invalidateLayout()
      }

      func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
      -> UICollectionViewCell
      {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        cell.contentView.backgroundColor = .orange
        return cell
      }

      func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
      -> Int
      {
        return 20
      }

      func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
      ) -> CGSize {
        return CGSize(
          width: min(collectionView.frame.width - 50, 300),
          height: collectionView.frame.height
        )
      }
    }

    try await assert(
      of: await CollectionViewController(),
      as: [
        "ipad": .image(layout: .device(.iPadPro12_9)),
        "iphoneSe": .image(layout: .device(.iPhoneSE)),
        "iphone8": .image(layout: .device(.iPhone8)),
        "iphoneMax": .image(layout: .device(.iPhoneXSMax)),
      ]
    )
#endif
  }

  @MainActor
  func testTraitsWithView() async throws {

    var label: UILabel {
      get async {
        await MainActor.run {
          let label = UILabel()
          label.font = .preferredFont(forTextStyle: .title1)
          label.adjustsFontForContentSizeCategory = true
          label.text = "What's the point?"
          return label
        }
      }
    }

    for (name, contentSize) in allContentSizes {
      try await assert(
        of: await label,
        as: .image(traits: .init(preferredContentSizeCategory: contentSize)),
        named: "label-\(name)"
      )
    }
  }

  @MainActor
  func testTraitsWithViewController() async throws {
#if os(iOS)
    class MyViewController: UIViewController {

      override func viewDidLoad() {
        super.viewDidLoad()
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title1)
        label.adjustsFontForContentSizeCategory = true
        label.text = "What's the point?"

        view.addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
          label.leadingAnchor.constraint(
            equalTo: view.layoutMarginsGuide.leadingAnchor),
          label.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
          label.trailingAnchor.constraint(
            equalTo: view.layoutMarginsGuide.trailingAnchor),
        ])
      }
    }

    for (name, contentSize) in allContentSizes {
      try await assert(
        of: await MyViewController(),
        as: .recursiveDescription(
          layout: .device(.iPhoneSE),
          traits: .init(preferredContentSizeCategory: contentSize)
        ),
        named: "label-\(name)",
        record: .never
      )
    }
#endif
  }

  @MainActor
  func testUIView() async throws {
#if os(iOS)
    let view = UIButton(type: .contactAdd)
    try await assert(of: view, as: .image)
    try await assert(of: view, as: .recursiveDescription)
#endif
  }

  @MainActor
  func testUIViewControllerLifeCycle() async throws {
#if os(iOS)
    class ViewController: UIViewController {

      let viewDidLoadExpectation: XCTestExpectation
      let viewWillAppearExpectation: XCTestExpectation
      let viewDidAppearExpectation: XCTestExpectation
      let viewWillDisappearExpectation: XCTestExpectation
      let viewDidDisappearExpectation: XCTestExpectation

      init(
        viewDidLoadExpectation: XCTestExpectation,
        viewWillAppearExpectation: XCTestExpectation,
        viewDidAppearExpectation: XCTestExpectation,
        viewWillDisappearExpectation: XCTestExpectation,
        viewDidDisappearExpectation: XCTestExpectation
      ) {
        self.viewDidLoadExpectation = viewDidLoadExpectation
        self.viewWillAppearExpectation = viewWillAppearExpectation
        self.viewDidAppearExpectation = viewDidAppearExpectation
        self.viewWillDisappearExpectation = viewWillDisappearExpectation
        self.viewDidDisappearExpectation = viewDidDisappearExpectation
        super.init(nibName: nil, bundle: nil)
      }
      required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
      }
      override func viewDidLoad() {
        super.viewDidLoad()
        viewDidLoadExpectation.fulfill()
      }
      override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearExpectation.fulfill()
      }
      override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppearExpectation.fulfill()
      }
      override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillDisappearExpectation.fulfill()
      }
      override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewDidDisappearExpectation.fulfill()
      }
    }

    let viewDidLoadExpectation = expectation(description: "viewDidLoad")
    let viewWillAppearExpectation = expectation(description: "viewWillAppear")
    let viewDidAppearExpectation = expectation(description: "viewDidAppear")
    let viewWillDisappearExpectation = expectation(description: "viewWillDisappear")
    let viewDidDisappearExpectation = expectation(description: "viewDidDisappear")

    viewDidLoadExpectation.expectedFulfillmentCount = 1
    viewWillAppearExpectation.expectedFulfillmentCount = 2
    viewDidAppearExpectation.expectedFulfillmentCount = 2
    viewWillDisappearExpectation.expectedFulfillmentCount = 2
    viewDidDisappearExpectation.expectedFulfillmentCount = 2

    let viewController = ViewController(
      viewDidLoadExpectation: viewDidLoadExpectation,
      viewWillAppearExpectation: viewWillAppearExpectation,
      viewDidAppearExpectation: viewDidAppearExpectation,
      viewWillDisappearExpectation: viewWillDisappearExpectation,
      viewDidDisappearExpectation: viewDidDisappearExpectation
    )

    try await assert(of: viewController, as: .image)
    try await assert(of: viewController, as: .image)

    await fulfillment(
      of: [
        viewDidLoadExpectation,
        viewWillAppearExpectation,
        viewDidAppearExpectation,
        viewWillDisappearExpectation,
        viewDidDisappearExpectation,
      ], timeout: 1, enforceOrder: true)
#endif
  }

  @MainActor
  func testViewControllerHierarchy() async throws {
#if os(iOS)
    let page = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    page.setViewControllers([UIViewController()], direction: .forward, animated: false)
    let tab = UITabBarController()
    tab.viewControllers = [
      UINavigationController(rootViewController: page),
      UINavigationController(rootViewController: UIViewController()),
      UINavigationController(rootViewController: UIViewController()),
      UINavigationController(rootViewController: UIViewController()),
      UINavigationController(rootViewController: UIViewController()),
    ]
    try await assert(of: tab, as: .hierarchy)
#endif
  }

  func testURLRequest() throws {
    var get = URLRequest(url: URL(string: "https://www.pointfree.co/")!)
    get.addValue("pf_session={}", forHTTPHeaderField: "Cookie")
    get.addValue("text/html", forHTTPHeaderField: "Accept")
    get.addValue("application/json", forHTTPHeaderField: "Content-Type")
    try assert(of: get, as: .raw, named: "get")
    try assert(of: get, as: .curl, named: "get-curl")

    var getWithQuery = URLRequest(
      url: URL(string: "https://www.pointfree.co?key_2=value_2&key_1=value_1&key_3=value_3")!)
    getWithQuery.addValue("pf_session={}", forHTTPHeaderField: "Cookie")
    getWithQuery.addValue("text/html", forHTTPHeaderField: "Accept")
    getWithQuery.addValue("application/json", forHTTPHeaderField: "Content-Type")
    try assert(
      of: getWithQuery,
      as: .raw,
      named: "get-with-query"
    )
    try assert(
      of: getWithQuery,
      as: .curl,
      named: "get-with-query-curl"
    )

    var post = URLRequest(url: URL(string: "https://www.pointfree.co/subscribe")!)
    post.httpMethod = "POST"
    post.addValue("pf_session={\"user_id\":\"0\"}", forHTTPHeaderField: "Cookie")
    post.addValue("text/html", forHTTPHeaderField: "Accept")
    post.httpBody = Data("pricing[billing]=monthly&pricing[lane]=individual".utf8)
    try assert(
      of: post,
      as: .raw,
      named: "post"
    )
    try assert(
      of: post,
      as: .curl,
      named: "post-curl"
    )

    var postWithJSON = URLRequest(
      url: URL(string: "http://dummy.restapiexample.com/api/v1/create")!)
    postWithJSON.httpMethod = "POST"
    postWithJSON.addValue("application/json", forHTTPHeaderField: "Content-Type")
    postWithJSON.addValue("application/json", forHTTPHeaderField: "Accept")
    postWithJSON.httpBody = Data(
      "{\"name\":\"tammy134235345235\", \"salary\":0, \"age\":\"tammy133\"}".utf8)
    try assert(
      of: postWithJSON,
      as: .raw,
      named: "post-with-json"
    )
    try assert(
      of: postWithJSON,
      as: .curl,
      named: "post-with-json-curl"
    )

    var head = URLRequest(url: URL(string: "https://www.pointfree.co/")!)
    head.httpMethod = "HEAD"
    head.addValue("pf_session={}", forHTTPHeaderField: "Cookie")
    try assert(of: head, as: .raw, named: "head")
    try assert(of: head, as: .curl, named: "head-curl")

    post = URLRequest(url: URL(string: "https://www.pointfree.co/subscribe")!)
    post.httpMethod = "POST"
    post.addValue("pf_session={\"user_id\":\"0\"}", forHTTPHeaderField: "Cookie")
    post.addValue("application/json", forHTTPHeaderField: "Accept")
    post.httpBody = Data(
      """
      {"pricing": {"lane": "individual","billing": "monthly"}}
      """.utf8)
  }

  @MainActor
  func testWebView() async throws {
#if os(iOS) || os(macOS)
    let fixtureUrl = URL(fileURLWithPath: #filePath, isDirectory: false)
      .deletingLastPathComponent()
      .appendingPathComponent("__Fixtures__/pointfree.html")
    let html = try String(contentsOf: fixtureUrl)
    let webView = WKWebView()
    webView.loadHTMLString(html, baseURL: nil)
    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
      try await assert(
        of: webView,
        as: .image(
          precision: 0.95,
          layout: .fixed(width: 800, height: 600)
        ),
        named: platform
      )
    }
#endif
  }

  @MainActor
  func testViewWithZeroHeightOrWidth() async throws {
#if os(iOS) || os(tvOS)
    var rect = CGRect(x: 0, y: 0, width: 350, height: 0)
    let redView = UIView(frame: rect)
    redView.backgroundColor = .red
    try await assert(of: redView, as: .image, named: "noHeight")

    rect = CGRect(x: 0, y: 0, width: 0, height: 350)
    let greenView = UIView(frame: rect)
    greenView.backgroundColor = .green
    try await assert(of: greenView, as: .image, named: "noWidth")

    rect = CGRect(x: 0, y: 0, width: 0, height: 0)
    let blueView = UIView(frame: rect)
    blueView.backgroundColor = .blue
    try await assert(of: blueView, as: .image, named: "noWidth.noHeight")
#endif
  }

  @MainActor
  func testViewAgainstEmptyImage() async throws {
#if os(iOS) || os(tvOS)
    let rect = CGRect(x: 0, y: 0, width: 0, height: 0)
    let view = UIView(frame: rect)
    view.backgroundColor = .blue

    let failure = try await verify(
      of: view,
      as: .image,
      named: "notEmptyImage"
    )

    XCTAssertNotNil(failure)
#endif
  }

  @MainActor
  func testEmbeddedWebView() async throws {
#if os(iOS)
    let label = UILabel()
    label.text = "Hello, Blob!"

    let fixtureUrl = URL(fileURLWithPath: #filePath, isDirectory: false)
      .deletingLastPathComponent()
      .appendingPathComponent("__Fixtures__/pointfree.html")
    let html = try String(contentsOf: fixtureUrl)
    let webView = WKWebView()
    webView.loadHTMLString(html, baseURL: nil)
    webView.isHidden = true

    let stackView = UIStackView(arrangedSubviews: [label, webView])
    stackView.axis = .vertical

    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
      try await assert(
        of: stackView,
        as: .image(layout: .fixed(width: 800, height: 600)),
        named: platform
      )
    }
#endif
  }

#if os(iOS) || os(macOS)
  final class ManipulatingWKWebViewNavigationDelegate: NSObject, WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      webView.evaluateJavaScript("document.body.children[0].classList.remove(\"hero\")")  // Change layout
    }
  }

  @MainActor
  func testWebViewWithManipulatingNavigationDelegate() async throws {
    let manipulatingWKWebViewNavigationDelegate = ManipulatingWKWebViewNavigationDelegate()
    let webView = WKWebView()
    webView.navigationDelegate = manipulatingWKWebViewNavigationDelegate

    let fixtureUrl = URL(fileURLWithPath: #filePath, isDirectory: false)
      .deletingLastPathComponent()
      .appendingPathComponent("__Fixtures__/pointfree.html")
    let html = try String(contentsOf: fixtureUrl)
    webView.loadHTMLString(html, baseURL: nil)
    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
      try await assert(
        of: webView,
        as: .image(layout: .fixed(width: 800, height: 600)),
        named: platform
      )
    }
    _ = manipulatingWKWebViewNavigationDelegate
  }

  final class CancellingWKWebViewNavigationDelegate: NSObject, WKNavigationDelegate {
    func webView(
      _ webView: WKWebView,
      decidePolicyFor navigationAction: WKNavigationAction,
      decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
    ) {
      decisionHandler(.cancel)
    }
  }

  @MainActor
  func testWebViewWithCancellingNavigationDelegate() async throws {
    let cancellingWKWebViewNavigationDelegate = CancellingWKWebViewNavigationDelegate()
    let webView = WKWebView()
    webView.navigationDelegate = cancellingWKWebViewNavigationDelegate

    let fixtureUrl = URL(fileURLWithPath: #filePath, isDirectory: false)
      .deletingLastPathComponent()
      .appendingPathComponent("__Fixtures__/pointfree.html")
    let html = try String(contentsOf: fixtureUrl)
    webView.loadHTMLString(html, baseURL: nil)
    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
      try await assert(
        of: webView,
        as: .image(precision: 0.95, layout: .fixed(width: 800, height: 600)),
        named: platform
      )
    }
    _ = cancellingWKWebViewNavigationDelegate
  }
#endif

#if os(iOS)
  @available(iOS 13.0, *)
  @MainActor
  func testSwiftUIView_iOS() async throws {
    @MainActor
    struct MyView: SwiftUI.View {
      var body: some SwiftUI.View {
        HStack {
          Image(systemName: "checkmark.circle.fill")
          Text("Checked").fixedSize()
        }
        .padding(5)
        .background(RoundedRectangle(cornerRadius: 5.0).fill(Color.blue))
        .padding(10)
        .background(Color.yellow)
      }
    }

    let view = MyView()

    try await withTestingEnvironment {
      $0.traits = .init(userInterfaceStyle: .light)
    } operation: {
      try await assert(
        of: view,
        as: .image
      )
      try await assert(
        of: view,
        as: .image(layout: .sizeThatFits),
        named: "size-that-fits"
      )
      try await assert(
        of: view,
        as: .image(layout: .fixed(width: 200.0, height: 100.0)),
        named: "fixed"
      )
      try await assert(
        of: view,
        as: .image(layout: .device(.iPhoneSE)),
        named: "device"
      )
    }
  }
#endif

#if os(tvOS)
  @available(tvOS 13.0, *)
  func testSwiftUIView_tvOS() {
    struct MyView: SwiftUI.View {
      var body: some SwiftUI.View {
        HStack {
          Image(systemName: "checkmark.circle.fill")
          Text("Checked").fixedSize()
        }
        .padding(5)
        .background(RoundedRectangle(cornerRadius: 5.0).fill(Color.blue))
        .padding(10)
      }
    }
    let view = MyView().background(Color.yellow)

    try await assert(of: view, as: .image())
    try await assert(of: view, as: .image(layout: .sizeThatFits), named: "size-that-fits")
    try await assert(
      of: view, as: .image(layout: .fixed(width: 300.0, height: 100.0)), named: "fixed")
    try await assert(of: view, as: .image(layout: .device(.tv)), named: "device")
  }
#endif
}

#if os(iOS)
private let allContentSizes =
[
  "extra-small": UIContentSizeCategory.extraSmall,
  "small": .small,
  "medium": .medium,
  "large": .large,
  "extra-large": .extraLarge,
  "extra-extra-large": .extraExtraLarge,
  "extra-extra-extra-large": .extraExtraExtraLarge,
  "accessibility-medium": .accessibilityMedium,
  "accessibility-large": .accessibilityLarge,
  "accessibility-extra-large": .accessibilityExtraLarge,
  "accessibility-extra-extra-large": .accessibilityExtraExtraLarge,
  "accessibility-extra-extra-extra-large": .accessibilityExtraExtraExtraLarge,
]
#endif
