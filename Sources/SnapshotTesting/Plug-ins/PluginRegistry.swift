import ImageSerializationPlugin

public class PluginRegistry {
  public static let shared = PluginRegistry()
  private var plugins: [String: ImageSerializationPlugin] = [:]
  
  private init() {}
  
  public func registerPlugin(_ plugin: ImageSerializationPlugin) {
    plugins[type(of: plugin).identifier] = plugin
  }
  
  public func plugin(for identifier: String) -> ImageSerializationPlugin? {
    return plugins[identifier]
  }
  
  public func allPlugins() -> [ImageSerializationPlugin] {
    return Array(plugins.values)
  }
}

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
    if let cls: AnyClass = classes[i], class_conformsToProtocol(cls, ImageSerializationPlugin.self) {
      if let pluginType = cls as? ImageSerializationPlugin.Type {
        PluginRegistry.shared.registerPlugin(pluginType.init())
      }
    }
  }
  classes.deallocate()
}

