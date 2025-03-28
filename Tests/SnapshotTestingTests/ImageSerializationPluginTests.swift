#if canImport(SwiftUI)
import XCTest
import SnapshotTestingPlugin
@testable import SnapshotTesting
import ImageSerializationPlugin

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

class MockImageSerializationPlugin: ImageSerializationPlugin {
  
  static var imageFormat: ImageSerializationFormat = .plugins("mock")
  
  func encodeImage(_ image: SnapImage) -> Data? {
    return "mockImageData".data(using: .utf8)
  }
  
  func decodeImage(_ data: Data) -> SnapImage? {
    let mockImage = SnapImage()
    return mockImage
  }
  
  // MARK: - SnapshotTestingPlugin
  static var identifier: String = "ImageSerializationPlugin.MockImageSerializationPlugin.mock"
  required init() {}
}

class ImageSerializerTests: XCTestCase {
  
  var imageSerializer: ImageSerializer!
  // #E48900FF
  var _1pxOrangePNGImage = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAAaADAAQAAAABAAAAAQAAAAD5Ip3+AAAADUlEQVQIHWN40snwHwAGLwJteELaggAAAABJRU5ErkJggg==")!
  
  override func setUp() {
    super.setUp()
    PluginRegistry.reset() // Reset state before each test
    
    // Register the mock plugins in the PluginRegistry
    PluginRegistry.registerPlugin(MockImageSerializationPlugin() as SnapshotTestingPlugin)
    
    imageSerializer = ImageSerializer()
  }
  
  override func tearDown() {
    imageSerializer = nil
    PluginRegistry.reset() // Reset state after each test
    super.tearDown()
  }
  
  func testEncodeImageUsingMockPlugin() {
    let mockImage = SnapImage()
    let imageData = imageSerializer.encodeImage(
      mockImage,
      imageFormat: MockImageSerializationPlugin.imageFormat
    )
    
    XCTAssertNotNil(imageData, "Image data should not be nil for mock plugin.")
    XCTAssertEqual(String(data: imageData!, encoding: .utf8), "mockImageData")
  }
  
  func testDecodeImageUsingMockPlugin() {
    let mockData = "mockImageData".data(using: .utf8)!
    let decodedImage = imageSerializer.decodeImage(
      mockData,
      imageFormat: MockImageSerializationPlugin.imageFormat
    )
    
    XCTAssertNotNil(decodedImage, "Image should be decoded using the mock plugin.")
  }
  
  // TODO: 1PX png image data
  func testEncodeImageAsPNG() {
    let mockImage = SnapImage()
    let imageData = imageSerializer.encodeImage(
      mockImage,
      imageFormat: .png
    )
    
    XCTAssertNil(imageData, "The image is empty it should be nil.")
  }
  
  func testDecodeImageAsPNG() {
    let decodedImage = imageSerializer.decodeImage(
      _1pxOrangePNGImage,
      imageFormat: .png
    )
    
    XCTAssertNotNil(decodedImage, "PNG image should be decoded successfully.")
    XCTAssertEqual(
      decodedImage?.size.width,
      1, "PNG image should be 1x1."
    )
    XCTAssertEqual(
      decodedImage?.size.height,
      1, "PNG image should be 1x1."
    )
    XCTAssertEqual(getFirstPixelColorHex(from: decodedImage!), "#E48900FF")
  }
  
  func testUnknownImageFormatFallsBackToPNG() {
    let mockImage = SnapImage(data: _1pxOrangePNGImage)!
    let imageData = imageSerializer.encodeImage(
      mockImage,
      imageFormat: .plugins("unknownFormat")
    )
    
    XCTAssertNotNil(imageData, "Unknown format should fall back to PNG encoding.")
  }
  
  func testPluginRegistryShouldContainRegisteredPlugins() {
    let plugins = PluginRegistry.allPlugins() as [ImageSerialization]
    
    XCTAssertEqual(plugins.count, 1, "There should be two registered plugins.")
    XCTAssertEqual(type(of: plugins[0]).imageFormat.rawValue, "mock", "The first plugin should support the 'mock' format.")
  }
}
#endif
