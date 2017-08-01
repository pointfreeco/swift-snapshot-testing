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
      let sceneView = SCNView(frame: .init(x: 0, y: 0, width: 500, height: 500))
      sceneView.scene = self
      return sceneView.snapshot()
    }
  }
#endif
