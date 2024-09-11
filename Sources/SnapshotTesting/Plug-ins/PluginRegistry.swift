#if canImport(SwiftUI) && canImport(ObjectiveC)
import ImageSerializationPlugin

@objc
public protocol SnapshotTestingPlugin {
  static var identifier: String { get }
  init()
}

public class PluginRegistry {
  public static let shared = PluginRegistry()
  private var plugins: [String: AnyObject] = [:]
  
  private init() {}
  
  public func registerPlugin(_ plugin: SnapshotTestingPlugin) {
    plugins[type(of: plugin).identifier] = plugin
  }
  
  public func plugin(for identifier: String) -> SnapshotTestingPlugin? {
    return plugins[identifier] as? SnapshotTestingPlugin
  }
  
  public func allPlugins() -> [SnapshotTestingPlugin] {
    return Array(plugins.values.compactMap { $0 as? SnapshotTestingPlugin })
  }
  
  public func imageSerializerPlugins() -> [ImageSerialization] {
    return Array(plugins.values).compactMap { $0 as? ImageSerialization  }
  }
}

// If we are not on macOS the autoregistration mechanism won't work.
#if canImport(ObjectiveC.runtime)
// MARK: - AutoRegistry
import Foundation
import ObjectiveC.runtime

var hasRegisterPlugins = false
func registerAllPlugins() {
  if hasRegisterPlugins { return }
  defer { hasRegisterPlugins = true }
  let count = objc_getClassList(nil, 0)
  let classes = UnsafeMutablePointer<AnyClass?>.allocate(capacity: Int(count))
  let autoreleasingClasses = AutoreleasingUnsafeMutablePointer<AnyClass>(classes)
  objc_getClassList(autoreleasingClasses, count)
  
  for i in 0..<Int(count) {
    if let cls: AnyClass = classes[i], class_conformsToProtocol(cls, SnapshotTestingPlugin.self) {
      if let pluginType = cls as? SnapshotTestingPlugin.Type {
        PluginRegistry.shared.registerPlugin(pluginType.init())
      }
    }
  }
  classes.deallocate()
}
#endif
#endif
