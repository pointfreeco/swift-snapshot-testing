import Foundation

#if !os(macOS)
import UIKit.UIImage
public typealias SnapImage = UIImage
#else
import AppKit.NSImage
public typealias SnapImage = NSImage
#endif

// I would like to have something like this as something that represent the fileformat/identifier
// but due to the limitation of @objc that can only represent have Int for RawType for enum i'ml blocked.
// I need this to behave like a string
public enum ImageSerializationFormat: RawRepresentable, Sendable {
  case png
  case plugins(String)
  
  public init?(rawValue: String) {
    switch rawValue {
    case "png": self = .png
    default: self = .plugins(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .png: return "png"
    case let .plugins(value): return value
    }
  }
}

public protocol ImageSerializationPublicFormat {
  static var imageFormat: ImageSerializationFormat { get }
}

@objc // Required initializer for creating instances dynamically
public protocol ImageSerializationPlugin {
  // This should be the fileExtention
  static var identifier: String { get }
  init() // Required initializer for creating instances dynamically
  func encodeImage(_ image: SnapImage) /*async throws*/ -> Data?
  func decodeImage(_ data: Data) /*async throws*/ -> SnapImage?
}
