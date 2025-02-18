#if canImport(SwiftUI) && canImport(ObjectiveC)

import XCTest

@testable import SnapshotTesting

#if os(iOS)
let platform = "ios"
#elseif os(tvOS)
let platform = "tvos"
#elseif os(macOS)
let platform = "macos"
extension NSTextField {
  var text: String {
    get { return self.stringValue }
    set { self.stringValue = newValue }
  }
}
#endif

#if os(macOS) || os(iOS) || os(tvOS)
extension CGPath {
  /// Creates an approximation of a heart at a 45º angle with a circle above, using all available element types:
  static var heart: CGPath {
    let scale: CGFloat = 30.0
    let path = CGMutablePath()
    
    path.move(to: CGPoint(x: 0.0 * scale, y: 0.0 * scale))
    path.addLine(to: CGPoint(x: 0.0 * scale, y: 2.0 * scale))
    path.addQuadCurve(
      to: CGPoint(x: 1.0 * scale, y: 3.0 * scale),
      control: CGPoint(x: 0.125 * scale, y: 2.875 * scale)
    )
    path.addQuadCurve(
      to: CGPoint(x: 2.0 * scale, y: 2.0 * scale),
      control: CGPoint(x: 1.875 * scale, y: 2.875 * scale)
    )
    path.addCurve(
      to: CGPoint(x: 3.0 * scale, y: 1.0 * scale),
      control1: CGPoint(x: 2.5 * scale, y: 2.0 * scale),
      control2: CGPoint(x: 3.0 * scale, y: 1.5 * scale)
    )
    path.addCurve(
      to: CGPoint(x: 2.0 * scale, y: 0.0 * scale),
      control1: CGPoint(x: 3.0 * scale, y: 0.5 * scale),
      control2: CGPoint(x: 2.5 * scale, y: 0.0 * scale)
    )
    path.addLine(to: CGPoint(x: 0.0 * scale, y: 0.0 * scale))
    path.closeSubpath()
    
    path.addEllipse(
      in: CGRect(
        origin: CGPoint(x: 2.0 * scale, y: 2.0 * scale),
        size: CGSize(width: scale, height: scale)
      ))
    
    return path
  }
}
#endif

#if os(iOS) || os(tvOS)
extension UIBezierPath {
  /// Creates an approximation of a heart at a 45º angle with a circle above, using all available element types:
  static var heart: UIBezierPath {
    UIBezierPath(cgPath: .heart)
  }
}
#endif

#if os(macOS)
extension NSBezierPath {
  /// Creates an approximation of a heart at a 45º angle with a circle above, using all available element types:
  static var heart: NSBezierPath {
    let scale: CGFloat = 30.0
    let path = NSBezierPath()
    
    path.move(to: CGPoint(x: 0.0 * scale, y: 0.0 * scale))
    path.line(to: CGPoint(x: 0.0 * scale, y: 2.0 * scale))
    path.curve(
      to: CGPoint(x: 1.0 * scale, y: 3.0 * scale),
      controlPoint1: CGPoint(x: 0.0 * scale, y: 2.5 * scale),
      controlPoint2: CGPoint(x: 0.5 * scale, y: 3.0 * scale)
    )
    path.curve(
      to: CGPoint(x: 2.0 * scale, y: 2.0 * scale),
      controlPoint1: CGPoint(x: 1.5 * scale, y: 3.0 * scale),
      controlPoint2: CGPoint(x: 2.0 * scale, y: 2.5 * scale)
    )
    path.curve(
      to: CGPoint(x: 3.0 * scale, y: 1.0 * scale),
      controlPoint1: CGPoint(x: 2.5 * scale, y: 2.0 * scale),
      controlPoint2: CGPoint(x: 3.0 * scale, y: 1.5 * scale)
    )
    path.curve(
      to: CGPoint(x: 2.0 * scale, y: 0.0 * scale),
      controlPoint1: CGPoint(x: 3.0 * scale, y: 0.5 * scale),
      controlPoint2: CGPoint(x: 2.5 * scale, y: 0.0 * scale)
    )
    path.line(to: CGPoint(x: 0.0 * scale, y: 0.0 * scale))
    path.close()
    
    path.appendOval(
      in: CGRect(
        origin: CGPoint(x: 2.0 * scale, y: 2.0 * scale),
        size: CGSize(width: scale, height: scale)
      ))
    
    return path
  }
}
#endif

#if canImport(UIKit)
import UIKit

func _getFirstPixelColorHex(from image: UIImage) -> String? {
  guard let cgImage = image.cgImage else { return nil }
  
  let pixelData = calloc(1, 4) // 4 bytes for RGBA
  let colorSpace = CGColorSpaceCreateDeviceRGB()
  let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
  
  guard let context = CGContext(
    data: pixelData,
    width: 1,
    height: 1,
    bitsPerComponent: 8,
    bytesPerRow: 4,
    space: colorSpace,
    bitmapInfo: bitmapInfo
  ) else {
    free(pixelData)
    return nil
  }
  
  // Draw the image in the 1x1 context to get the first pixel's color
  context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
  
  // Get the color components
  let data = pixelData!.assumingMemoryBound(to: UInt8.self)
  let r = data[0]
  let g = data[1]
  let b = data[2]
  let a = data[3]
  
  free(pixelData)
  
  // Return the hex string
  return String(format: "#%02X%02X%02X%02X", r, g, b, a)
}
#endif

#if canImport(AppKit)
import AppKit

func _getFirstPixelColorHex(from image: NSImage) -> String? {
  guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
  
  let pixelData = calloc(1, 4) // 4 bytes for RGBA
  let colorSpace = CGColorSpaceCreateDeviceRGB()
  let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
  
  guard let context = CGContext(
    data: pixelData,
    width: 1,
    height: 1,
    bitsPerComponent: 8,
    bytesPerRow: 4,
    space: colorSpace,
    bitmapInfo: bitmapInfo
  ) else {
    free(pixelData)
    return nil
  }
  
  // Draw the image in the 1x1 context to get the first pixel's color
  context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
  
  // Get the color components
  let data = pixelData!.assumingMemoryBound(to: UInt8.self)
  let r = data[0]
  let g = data[1]
  let b = data[2]
  let a = data[3]
  
  free(pixelData)
  
  // Return the hex string
  return String(format: "#%02X%02X%02X%02X", r, g, b, a)
}
#endif

#if canImport(UIKit)
typealias SnapImage = UIImage
#elseif canImport(AppKit)
typealias SnapImage = NSImage
#endif

func getFirstPixelColorHex(from image: SnapImage) -> String? {
#if canImport(UIKit)
  return _getFirstPixelColorHex(from: image)
#elseif canImport(AppKit)
  return _getFirstPixelColorHex(from: image)
#endif
}
#endif
