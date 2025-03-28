#if canImport(SwiftUI)
import XCTest
@testable import SnapshotTesting
import SnapshotTestingPlugin

class MockPlugin: NSObject, SnapshotTestingPlugin {
  static var identifier: String = "MockPlugin"
  
  required override init() {
    super.init()
  }
}

class AnotherMockPlugin: NSObject, SnapshotTestingPlugin {
  static var identifier: String = "AnotherMockPlugin"
  
  required override init() {
    super.init()
  }
}

final class PluginRegistryTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    PluginRegistry.reset() // Reset state before each test
  }
  
  override func tearDown() {
    PluginRegistry.reset() // Reset state after each test
    super.tearDown()
  }
  
  func testRegisterPlugin() {
    // Register a mock plugin
    PluginRegistry.registerPlugin(MockPlugin())
    
    // Retrieve the plugin by identifier
    let retrievedPlugin: MockPlugin? = PluginRegistry.plugin(for: MockPlugin.identifier)
    XCTAssertNotNil(retrievedPlugin)
  }
  
  func testRetrieveNonExistentPlugin() {
    // Try to retrieve a non-existent plugin
    let nonExistentPlugin: MockPlugin? = PluginRegistry.plugin(for: "NonExistentPlugin")
    XCTAssertNil(nonExistentPlugin)
  }
  
  func testAllPlugins() {
    // Register two mock plugins
    PluginRegistry.registerPlugin(MockPlugin())
    PluginRegistry.registerPlugin(AnotherMockPlugin())
    
    // Retrieve all plugins
    let allPlugins: [SnapshotTestingPlugin] = PluginRegistry.allPlugins()
    
    XCTAssertEqual(allPlugins.count, 2)
    XCTAssertTrue(allPlugins.contains { $0 is MockPlugin })
    XCTAssertTrue(allPlugins.contains { $0 is AnotherMockPlugin })
  }
}

#endif
