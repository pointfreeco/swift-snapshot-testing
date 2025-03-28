#if canImport(SwiftUI)
import Foundation
import SnapshotTestingPlugin

#if canImport(UIKit)
import UIKit.UIImage
/// A type alias for `UIImage` when UIKit is available.
public typealias SnapImage = UIImage
#elseif canImport(AppKit)
import AppKit.NSImage
/// A type alias for `NSImage` when AppKit is available.
public typealias SnapImage = NSImage
#endif

/// A type alias that combines `ImageSerialization` and `SnapshotTestingPlugin` protocols.
///
/// `ImageSerializationPlugin` is a convenient alias used to conform to both `ImageSerialization` and `SnapshotTestingPlugin` protocols.
/// This allows for image serialization plugins that also support snapshot testing, leveraging the Objective-C runtime while maintaining image serialization capabilities.
public typealias ImageSerializationPlugin = ImageSerialization & SnapshotTestingPlugin

// TODO: async throws will be added later to encodeImage and decodeImage
/// A protocol that defines methods for encoding and decoding images in various formats.
///
/// The `ImageSerialization` protocol is intended for classes that provide functionality to serialize (encode) and deserialize (decode) images.
/// Implementing this protocol allows a class to specify the image format it supports and to handle image data conversions.
/// This protocol is designed to be used in environments where SwiftUI is available and supports platform-specific image types via `SnapImage`.
public protocol ImageSerialization {
  
  /// The image format that the serialization plugin supports.
  ///
  /// Each conforming class must specify the format it handles, using the `ImageSerializationFormat` enum. This property helps the `ImageSerializer`
  /// determine which plugin to use for a given format during image encoding and decoding.
  static var imageFormat: ImageSerializationFormat { get }
  
  /// Encodes a `SnapImage` into a data representation.
  ///
  /// This method converts the provided image into the appropriate data format. It may eventually support asynchronous operations and error handling using `async throws`.
  ///
  /// - Parameter image: The image to be encoded.
  /// - Returns: The encoded image data, or `nil` if encoding fails.
  func encodeImage(_ image: SnapImage) -> Data?
  
  /// Decodes image data into a `SnapImage`.
  ///
  /// This method converts the provided data back into an image. It may eventually support asynchronous operations and error handling using `async throws`.
  ///
  /// - Parameter data: The image data to be decoded.
  /// - Returns: The decoded image, or `nil` if decoding fails.
  func decodeImage(_ data: Data) -> SnapImage?
}
#endif

/// An enumeration that defines the image formats supported by the `ImageSerialization` protocol.
///
/// The `ImageSerializationFormat` enum is used to represent various image formats. It includes a predefined case for PNG images and a flexible case for plugins,
/// allowing for the extension of formats via plugins identified by unique string values.
public enum ImageSerializationFormat: RawRepresentable, Sendable, Equatable {
  
  public static let defaultValue: ImageSerializationFormat = .png
  
  /// Represents the default image format aka PNG.
  case png
  
  /// Represents a custom image format provided by a plugin.
  ///
  /// This case allows for the extension of image formats beyond the predefined ones by using a unique string identifier.
  case plugins(String)
  
  /// Initializes an `ImageSerializationFormat` instance from a raw string value.
  ///
  /// This initializer converts a string value into an appropriate `ImageSerializationFormat` case.
  ///
  /// - Parameter rawValue: The string representation of the image format.
  public init?(rawValue: String) {
    self = rawValue == "png" ? .png : .plugins(rawValue)
  }
  
  /// The raw string value of the `ImageSerializationFormat`.
  ///
  /// This computed property returns the string representation of the current image format.
  public var rawValue: String {
    switch self {
      case .png: return "png"
      case let .plugins(value): return value
    }
  }
}
