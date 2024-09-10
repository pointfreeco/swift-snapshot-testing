import Foundation
import ImageSerializationPlugin

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

public class ImageSerializer {
  public init() {}
  
  // 🥲 waiting for SE-0438 to land https://github.com/swiftlang/swift-evolution/blob/main/proposals/0438-metatype-keypath.md
  // public func encodeImage(_ image: SnapImage, format: KeyPath<ImageSerializationFormat.Type, String>) -> Data? {

  public func encodeImage(_ image: SnapImage, format: String) /*async throws*/ -> Data? {
    for plugin in PluginRegistry.shared.allPlugins() {
      if type(of: plugin).fileExt == format {
        return /*try await*/ plugin.encodeImage(image)
      }
    }
    // Default to PNG
    return encodePNG(image)
  }
  
  public func decodeImage(_ data: Data, format: String) /*async throws*/ -> SnapImage? {
    for plugin in PluginRegistry.shared.allPlugins() {
      if type(of: plugin).fileExt == format {
        return /*try await*/ plugin.decodeImage(data)
      }
    }
    // Default to PNG
    return decodePNG(data)
  }
  
  // MARK: - Actual default Image Serializer
  private func encodePNG(_ image: SnapImage) -> Data? {
#if !os(macOS)
    return image.pngData()
#else
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return nil
    }
    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    return bitmapRep.representation(using: .png, properties: [:])
#endif
  }
  
  private func decodePNG(_ data: Data) -> SnapImage? {
#if !os(macOS)
    return UIImage(data: data)
#else
    return NSImage(data: data)
#endif
  }
}
