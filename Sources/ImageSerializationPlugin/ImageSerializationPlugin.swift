import Foundation

#if !os(macOS)
import UIKit.UIImage
public typealias SnapImage = UIImage
#else
import AppKit.NSImage
public typealias SnapImage = NSImage
#endif

// I need this to behave like a string
public enum ImageSerializationFormat: RawRepresentable {
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

@objc // Required initializer for creating instances dynamically
public protocol ImageSerializationPlugin {
  static var fileExt: String { get }
  init() // Required initializer for creating instances dynamically
  func encodeImage(_ image: SnapImage) /*async throws*/ -> Data?
  func decodeImage(_ data: Data) /*async throws*/ -> SnapImage?
}
