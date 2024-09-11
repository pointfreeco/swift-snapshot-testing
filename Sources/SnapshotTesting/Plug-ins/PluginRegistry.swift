#if canImport(SwiftUI) && canImport(ObjectiveC)
import Foundation
import ObjectiveC.runtime
import ImageSerializationPlugin
import SnapshotTestingPlugin

// MARK: - PluginRegistry
public class PluginRegistry {
  public static let shared = PluginRegistry()
  private var plugins: [String: AnyObject] = [:]

  private init() {
    defer { registerAllPlugins() }
  }
  
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
    
  /// Registers all classes that conform to the `SnapshotTestingPlugin` protocol.
  ///
  /// This function iterates over all classes known to the Objective-C runtime and registers any class
  /// that conforms to the `SnapshotTestingPlugin` protocol as a plugin. The plugin classes are expected to
  /// implement the `SnapshotTestingPlugin` protocol and have a parameterless initializer.
  ///
  /// The process is as follows:
  /// 1. The function first queries the Objective-C runtime to get the total number of classes.
  /// 2. It allocates memory to hold references to these classes.
  /// 3. It retrieves all class references into the allocated memory.
  /// 4. It then iterates through each class reference, checking if it conforms to the `SnapshotTestingPlugin` protocol.
  /// 5. If a class conforms, it is instantiated and registered as a plugin using the `registerPlugin(_:)` method.
  func registerAllPlugins() {
    let classCount = objc_getClassList(nil, 0)
    guard classCount > 0 else { return }
    
    let classes = UnsafeMutablePointer<AnyClass?>.allocate(capacity: Int(classCount))
    defer { classes.deallocate() }
    
    let autoreleasingClasses = AutoreleasingUnsafeMutablePointer<AnyClass>(classes)
    objc_getClassList(autoreleasingClasses, classCount)
    
    for i in 0..<Int(classCount) {
      guard
        let someClass = classes[i],
        let pluginType = someClass as? SnapshotTestingPlugin.Type
      else { continue }
      self.registerPlugin(pluginType.init())
    }
  }

}
#endif
