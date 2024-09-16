#if canImport(Foundation) && canImport(ObjectiveC)
import Foundation

/// A protocol that defines a plugin for snapshot testing, designed to be used in environments that support Objective-C.
///
/// The `SnapshotTestingPlugin` protocol is intended to be adopted by classes that provide specific functionality for snapshot testing.
/// It requires each conforming class to have a unique identifier and a parameterless initializer. This protocol is designed to be used in
/// environments where both Foundation and Objective-C are available, making it compatible with Objective-C runtime features.
///
/// Conforming classes must be marked with `@objc` to ensure compatibility with Objective-C runtime mechanisms.
@objc public protocol SnapshotTestingPlugin {

  /// A unique string identifier for the plugin.
  ///
  /// Each plugin must provide a static identifier that uniquely distinguishes it from other plugins. This identifier is used
  /// to register and retrieve plugins within a registry, ensuring that each plugin can be easily identified and utilized.
  static var identifier: String { get }

  /// Initializes a new instance of the plugin.
  ///
  /// This initializer is required to allow the Objective-C runtime to create instances of the plugin class when registering
  /// and utilizing plugins. The initializer must not take any parameters.
  init()
}
#endif
