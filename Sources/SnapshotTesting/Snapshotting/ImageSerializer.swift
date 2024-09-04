import Foundation
import JxlCoder

#if !os(macOS)
import UIKit.UIImage
public typealias SnapImage = UIImage

private func EncodePNGImage(_ image: SnapImage) -> Data? {
  return image.pngData()
}

private func DecodePNGImage(_ data: Data) -> SnapImage? {
  UIImage(data: data)
}

#else
import AppKit.NSImage
public typealias SnapImage = NSImage

private func EncodePNGImage(_ image: SnapImage) -> Data? {
  guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
  let rep = NSBitmapImageRep(cgImage: cgImage)
  rep.size = image.size
  return rep.representation(using: .png, properties: [:])
}

private func DecodePNGImage(_ data: Data) -> SnapImage? {
  NSImage(data: data)
}

#endif

package protocol DefaultValueProvider<Value> {
  associatedtype Value

  static var defaultValue: Value { get }
}

public enum ImageFormat: String, DefaultValueProvider {
  case jxl
  case png
  
  public static var defaultValue = ImageFormat.png
}

package func EncodeImage(image: SnapImage, _ format: ImageFormat) -> Data? {
  switch format {
    case .jxl: return try? JXLCoder.encode(image: image)
    case .png: return EncodePNGImage(image)
  }
}

package func DecodeImage(data: Data, _ format: ImageFormat) -> SnapImage? {
  switch format {
    case .jxl: return try? JXLCoder.decode(data: data)
    case .png: return DecodePNGImage(data)
  }
}

