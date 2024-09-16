#if canImport(SwiftUI)
import Foundation
import ImageSerializationPlugin

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A class responsible for encoding and decoding images using various image serialization plugins.
///
/// The `ImageSerializer` class leverages plugins that conform to the `ImageSerialization` protocol to encode and decode images in different formats.
/// It automatically retrieves all available image serialization plugins from the `PluginRegistry` and uses them based on the specified `ImageSerializationFormat`.
/// If no plugin is found for the requested format, it defaults to using PNG encoding/decoding.
class ImageSerializer {
  
  /// A collection of plugins that conform to the `ImageSerialization` protocol.
  private let plugins: [ImageSerialization]
  
  init() {
    self.plugins = PluginRegistry.allPlugins()
  }

  // TODO: async throws will be added later
  /// Encodes a given image into the specified image format using the appropriate plugin.
  ///
  /// This method attempts to encode the provided `SnapImage` into the desired format using the first plugin that supports the specified `ImageSerializationFormat`.
  /// If no plugin is found for the format, it defaults to encoding the image as PNG.
  ///
  /// - Parameters:
  ///   - image: The `SnapImage` to encode.
  ///   - imageFormat: The format in which to encode the image.
  /// - Returns: The encoded image data, or `nil` if encoding fails.
  func encodeImage(_ image: SnapImage, imageFormat: ImageSerializationFormat = .defaultValue) -> Data? {
    for plugin in self.plugins  {
      if type(of: plugin).imageFormat == imageFormat {
        return plugin.encodeImage(image)
      }
    }
    // Default to PNG
    return encodePNG(image)
  }
  
  // TODO: async throws will be added later
  /// Decodes image data into a `SnapImage` using the appropriate plugin based on the specified image format.
  ///
  /// This method attempts to decode the provided data into a `SnapImage` using the first plugin that supports the specified `ImageSerializationFormat`.
  /// If no plugin is found for the format, it defaults to decoding the data as PNG.
  ///
  /// - Parameters:
  ///   - data: The image data to decode.
  ///   - imageFormat: The format in which the image data is encoded.
  /// - Returns: The decoded `SnapImage`, or `nil` if decoding fails.
  func decodeImage(_ data: Data, imageFormat: ImageSerializationFormat = .defaultValue) -> SnapImage? {
    for plugin in self.plugins {
      if type(of: plugin).imageFormat == imageFormat {
        return plugin.decodeImage(data)
      }
    }
    // Default to PNG
    return decodePNG(data)
  }
  
  // MARK: - Actual default Image Serializer
  
  /// Encodes a `SnapImage` as PNG data.
  ///
  /// This method provides a default implementation for encoding images as PNG. It is used as a fallback if no suitable plugin is found for the requested format.
  ///
  /// - Parameter image: The `SnapImage` to encode.
  /// - Returns: The encoded PNG data, or `nil` if encoding fails.
  private func encodePNG(_ image: SnapImage) -> Data? {
#if canImport(UIKit)
    return image.pngData()
#elseif canImport(AppKit)
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return nil
    }
    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    return bitmapRep.representation(using: .png, properties: [:])
#endif
  }
  
  /// Decodes PNG data into a `SnapImage`.
  ///
  /// This method provides a default implementation for decoding PNG data into a `SnapImage`. It is used as a fallback if no suitable plugin is found for the requested format.
  ///
  /// - Parameter data: The PNG data to decode.
  /// - Returns: The decoded `SnapImage`, or `nil` if decoding fails.
  private func decodePNG(_ data: Data) -> SnapImage? {
#if canImport(UIKit)
    return UIImage(data: data)
#elseif canImport(AppKit)
    return NSImage(data: data)
#endif
  }
}
#endif
