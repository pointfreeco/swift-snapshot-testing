#if canImport(SwiftUI) && canImport(ObjectiveC)
import Foundation
import ObjectiveC.runtime
import ImageSerializationPlugin
import SnapshotTestingPlugin

/// A singleton class responsible for managing and registering plugins conforming to the `SnapshotTestingPlugin` protocol.
///
/// The `PluginRegistry` class automatically discovers and registers all classes that conform to the `SnapshotTestingPlugin` protocol
/// within the Objective-C runtime. It provides methods to retrieve specific plugins by their identifier, get all registered plugins,
/// and filter plugins that conform to the `ImageSerialization` protocol.
public class PluginRegistry {
  /// The shared instance of the `PluginRegistry`, providing a single point of access.
  public static let shared = PluginRegistry()

  /// A dictionary holding the registered plugins, keyed by their identifier.
  private var plugins: [String: AnyObject] = [:]

  /// Private initializer to enforce the singleton pattern.
  ///
  /// Upon initialization, the registry automatically calls `registerAllPlugins()` to discover and register plugins.
  private init() {
    defer { registerAllPlugins() }
  }
  
  /// Registers a given plugin in the registry.
  ///
  /// - Parameter plugin: An instance of a class conforming to `SnapshotTestingPlugin`.
  public func registerPlugin(_ plugin: SnapshotTestingPlugin) {
    plugins[type(of: plugin).identifier] = plugin
  }

  /// Retrieves a plugin from the registry by its identifier and casts it to the specified type.
  ///
  /// This method attempts to find a plugin in the registry that matches the given identifier and cast it to the specified generic type `Output`.
  /// If the plugin exists and can be cast to the specified type, it is returned; otherwise, `nil` is returned.
  ///
  /// - Parameter identifier: A unique string identifier for the plugin.
  /// - Returns: The plugin instance cast to the specified type `Output` if found and castable, otherwise `nil`.
  public func plugin<Output>(for identifier: String) -> Output? {
    return plugins[identifier] as? Output
  }
  
  /// Returns all registered plugins that can be cast to the specified type.
  ///
  /// This method retrieves all registered plugins and attempts to cast each one to the specified generic type `Output`.
  /// Only the plugins that can be successfully cast to `Output` are included in the returned array.
  ///
  /// - Returns: An array of all registered plugins that can be cast to the specified type `Output`.
  public func allPlugins<Output>() -> [Output] {
    return Array(plugins.values.compactMap { $0 as? Output })
  }
    
  /// Discovers and registers all classes that conform to the `SnapshotTestingPlugin` protocol.
  ///
  /// This method iterates over all classes in the Objective-C runtime, identifies those that conform to the `SnapshotTestingPlugin`
  /// protocol, and registers them as plugins. The plugins are expected to have a parameterless initializer.
  ///
  /// The process is as follows:
  /// 1. The function queries the Objective-C runtime for the total number of classes.
  /// 2. Memory is allocated to hold references to these classes.
  /// 3. All class references are retrieved into the allocated memory.
  /// 4. Each class reference is checked for conformance to the `SnapshotTestingPlugin` protocol.
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
        class_conformsToProtocol(someClass, SnapshotTestingPlugin.self),
        let pluginType = someClass as? SnapshotTestingPlugin.Type
      else { continue }
      self.registerPlugin(pluginType.init())
    }
  }

}
#endif
