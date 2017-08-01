import SceneKit
import SnapshotTesting
import XCTest

class SceneKitTests: XCTestCase {
  func testScene() {
    let scene = SCNScene()

    let sphereGeometry = SCNSphere(radius: 3)
    sphereGeometry.segmentCount = 200
    let sphereNode = SCNNode(geometry: sphereGeometry)
    sphereNode.position = SCNVector3Zero
    scene.rootNode.addChildNode(sphereNode)

    sphereGeometry.firstMaterial?.diffuse.contents = earthImage()

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

    #if os(macOS)
      assertSnapshot(matching: scene, identifier: "mac")
    #endif
    #if os(iOS)
      assertSnapshot(matching: scene, identifier: "ios")
    #endif
  }
}

private func currentFilePath(file: StaticString = #file) -> String {
  return String.init(describing: file)
}

#if os(macOS)
  private func earthImage() -> NSImage {
    return NSImage(contentsOf: earthImageUrl())!
  }
#endif
#if os(iOS)
  private func earthImage() -> UIImage {
    return UIImage(contentsOfFile: earthImageUrl().path)!
  }
#endif

private func earthImageUrl() -> URL {
  return .init(
    fileURLWithPath:
    "/" + currentFilePath().split(separator: "/").dropLast().joined(separator: "/") + "/assets/earth.png"
  )
}
