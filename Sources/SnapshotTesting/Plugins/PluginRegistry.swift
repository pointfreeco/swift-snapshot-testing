#if canImport(SwiftUI) && canImport(ObjectiveC)
import Foundation
import ObjectiveC.runtime
import SnapshotTestingPlugin

/// A singleton class responsible for managing and registering plugins conforming to the `SnapshotTestingPlugin` protocol.
///
/// The `PluginRegistry` automatically discovers and registers classes conforming to the `SnapshotTestingPlugin` protocol
/// within the Objective-C runtime. It allows retrieval of specific plugins by identifier, access to all registered plugins,
/// and filtering of plugins that conform to the `ImageSerialization` protocol.
class PluginRegistry {
  
  /// Shared singleton instance of `PluginRegistry`.
  private static let shared = PluginRegistry()
  
  /// Dictionary holding registered plugins, keyed by their identifier.
  private var plugins: [String: AnyObject] = [:]
  
  /// Private initializer enforcing the singleton pattern.
  ///
  /// Automatically triggers `automaticPluginRegistration()` to discover and register plugins.
  private init() {
    defer { automaticPluginRegistration() }
  }
  
  // MARK: - Internal Methods
  
  /// Registers a plugin.
  ///
  /// - Parameter plugin: An instance conforming to `SnapshotTestingPlugin`.
  static func registerPlugin(_ plugin: any SnapshotTestingPlugin) {
    PluginRegistry.shared.registerPlugin(plugin)
  }
  
  /// Retrieves a plugin by its identifier, casting it to the specified type.
  ///
  /// - Parameter identifier: The unique identifier for the plugin.
  /// - Returns: The plugin instance cast to `Output` if found and castable, otherwise `nil`.
  static func plugin<Output>(for identifier: String) -> Output? {
    PluginRegistry.shared.plugin(for: identifier)
  }
  
  /// Returns all registered plugins cast to the specified type.
  ///
  /// - Returns: An array of all registered plugins that can be cast to `Output`.
  static func allPlugins<Output>() -> [Output] {
    PluginRegistry.shared.allPlugins()
  }
  
  // MARK: - Internal Methods
  
  /// Registers a plugin.
  ///
  /// - Parameter plugin: An instance conforming to `SnapshotTestingPlugin`.
  private func registerPlugin(_ plugin: SnapshotTestingPlugin) {
    plugins[type(of: plugin).identifier] = plugin
  }
  
  /// Retrieves a plugin by its identifier, casting it to the specified type.
  ///
  /// - Parameter identifier: The unique identifier for the plugin.
  /// - Returns: The plugin instance cast to `Output` if found and castable, otherwise `nil`.
  private func plugin<Output>(for identifier: String) -> Output? {
    return plugins[identifier] as? Output
  }
  
  /// Returns all registered plugins cast to the specified type.
  ///
  /// - Returns: An array of all registered plugins that can be cast to `Output`.
  private func allPlugins<Output>() -> [Output] {
    return Array(plugins.values.compactMap { $0 as? Output })
  }
  
  /// Discovers and registers all classes conforming to the `SnapshotTestingPlugin` protocol.
  ///
  /// This method iterates over all Objective-C runtime classes, identifying those that conform to `SnapshotTestingPlugin`,
  /// instantiating them, and registering them as plugins.
  private func automaticPluginRegistration() {
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
  
  // TEST-ONLY Reset Method
  #if DEBUG
  internal static func reset() {
      shared.plugins.removeAll()
  }

  internal static func automaticPluginRegistration() {
      shared.automaticPluginRegistration()
  }
  #endif
}
#endif
