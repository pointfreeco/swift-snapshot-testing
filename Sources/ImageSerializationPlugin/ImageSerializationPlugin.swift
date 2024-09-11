#if canImport(SwiftUI)
import Foundation
import SnapshotTestingPlugin

#if canImport(UIKit)
import UIKit.UIImage
public typealias SnapImage = UIImage
#elseif canImport(AppKit)
import AppKit.NSImage
public typealias SnapImage = NSImage
#endif

// Way to go around the limitation of @objc
public typealias ImageSerializationPlugin = ImageSerialization & SnapshotTestingPlugin

public protocol ImageSerialization {
  static var imageFormat: ImageSerializationFormat { get }
  func encodeImage(_ image: SnapImage) /*async throws*/ -> Data?
  func decodeImage(_ data: Data) /*async throws*/ -> SnapImage?
}
#endif

public enum ImageSerializationFormat: RawRepresentable, Sendable, Equatable {
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
