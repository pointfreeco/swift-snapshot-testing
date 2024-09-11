#if canImport(SwiftUI)
import Foundation

#if canImport(UIKit)
import UIKit.UIImage
public typealias SnapImage = UIImage
#elseif canImport(AppKit)
import AppKit.NSImage
public typealias SnapImage = NSImage
#endif

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
#endif

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
