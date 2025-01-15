#if canImport(SwiftUI) && canImport(ObjectiveC)
import XCTest
import ObjectiveC
@testable import SnapshotTesting
import SnapshotTestingPlugin

final class PluginRegistryAutomaticRegistrationTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    PluginRegistry.reset() // Reset state before each test
  }
  
  override func tearDown() {
    PluginRegistry.reset() // Reset state after each test
    super.tearDown()
  }
  
  func testAutomaticPluginRegistration() {
    // Automatically register plugins using the Objective-C runtime
    PluginRegistry.automaticPluginRegistration()
    
    // Verify if the mock plugin was automatically registered
    let registeredPlugin: MockPlugin? = PluginRegistry.plugin(for: MockPlugin.identifier)
    XCTAssertNotNil(registeredPlugin)
  }
}
#endif
