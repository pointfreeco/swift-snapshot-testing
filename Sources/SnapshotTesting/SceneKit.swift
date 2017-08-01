import SceneKit

#if os(macOS)
  extension SCNScene: Snapshot {
    public var snapshotFormat: NSImage {
      let sceneView = SCNView(frame: .init(x: 0, y: 0, width: 500, height: 500))
      sceneView.scene = self
      return sceneView.snapshot()
    }
  }
#endif

#if os(iOS)
  extension SCNScene: Snapshot {
    public var snapshotFormat: UIImage {
      let vc = UIViewController()
      let sceneView = SCNView(frame: .init(x: 0, y: 0, width: 500, height: 500))
      vc.view = sceneView
      sceneView.scene = self

      let snapshot = sceneView.snapshot()
      let scaledSize = CGSize(
        width: snapshot.size.width / sceneView.contentScaleFactor,
        height: snapshot.size.height / sceneView.contentScaleFactor
      )

      UIGraphicsBeginImageContextWithOptions(scaledSize, false, sceneView.contentScaleFactor)
      defer { UIGraphicsEndImageContext() }
      snapshot.draw(in: .init(origin: .zero, size: scaledSize))
      return UIGraphicsGetImageFromCurrentImageContext()!
    }
  }
#endif
