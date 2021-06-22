@testable import SnapshotTesting
import XCTest

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

    path.addEllipse(in: CGRect(
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

    path.appendOval(in: CGRect(
      origin: CGPoint(x: 2.0 * scale, y: 2.0 * scale),
      size: CGSize(width: scale, height: scale)
    ))

    return path
  }
}
#endif

#if os(iOS) || os(tvOS)
extension CGColor {

  static var blackComponents: UnsafeMutablePointer<CGFloat> {
    get {
      let data = UnsafeMutablePointer<CGFloat>.allocate(capacity: 4)
      data[0] = 0.0
      data[1] = 0.0
      data[2] = 0.0
      data[3] = 1.0
      return data
    }
  }

  static var black: CGColor {
    get {
      CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, components: blackComponents)!
    }
  }

  static var whiteComponents: UnsafeMutablePointer<CGFloat> {
    get {
      let data = UnsafeMutablePointer<CGFloat>.allocate(capacity: 4)
      data[0] = 1.0
      data[1] = 1.0
      data[2] = 1.0
      data[3] = 1.0
      return data
    }
  }

  static var white: CGColor {
    get {
      CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, components: whiteComponents)!
    }
  }
}
#endif

#if os(macOS) || os(iOS) || os(tvOS)
private let heartDimension = 180

private let largeHeartDimension = 2048

extension CGImage {

  /// Creates an approximation of a heart at a 45º angle with a circle above.
  static var heart: CGImage {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let context = CGContext(
      data:               nil,
      width:              heartDimension,
      height:             heartDimension,
      bitsPerComponent:   8,
      bytesPerRow:        heartDimension * 4,
      space:              space,
      bitmapInfo:         CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.setFillColor(CGColor.black)
    context.fill(CGRect(x: 0,y: 0,width: heartDimension,height: heartDimension))
    context.setFillColor(CGColor.white)
    context.addPath(CGPath.heart)
    context.drawPath(using: .fill)
    return context.makeImage()!
  }

  /// Creates an approximation of a heart at a 45º angle with a circle above
  /// with each component values off-by=one when compared to reference image.
  static var heartOffByOne: CGImage {
    let bytesPerRow = heartDimension * 4
    let dataCount = heartDimension * bytesPerRow
    let data = UnsafeMutablePointer<UInt8>.allocate(capacity: dataCount)
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let context = CGContext(
      data:               data,
      width:              heartDimension,
      height:             heartDimension,
      bitsPerComponent:   8,
      bytesPerRow:        heartDimension * 4,
      space:              space,
      bitmapInfo:         CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.setFillColor(CGColor.black)
    context.fill(CGRect(x: 0,y: 0,width: heartDimension,height: heartDimension))
    context.setFillColor(CGColor.white)
    context.addPath(CGPath.heart)
    context.drawPath(using: .fill)

    let medianData = UInt8.max / 2

    for i in 0..<dataCount {

      if data[i] > medianData {
        data[i] = data[i] - 1
      }
      else {
        data[i] = data[i] + 1
      }
    }

    return context.makeImage()!
  }

  /// Creates an approximation of a heart at a 45º angle with a circle above.
  static var largeHeart: CGImage {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let context = CGContext(
      data:               nil,
      width:              largeHeartDimension,
      height:             largeHeartDimension,
      bitsPerComponent:   8,
      bytesPerRow:        largeHeartDimension * 4,
      space:              space,
      bitmapInfo:         CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.setFillColor(CGColor.black)
    context.fill(CGRect(x: 0,y: 0,width: largeHeartDimension,height: largeHeartDimension))
    context.setFillColor(CGColor.white)
    context.addPath(CGPath.heart)
    context.drawPath(using: .fill)
    return context.makeImage()!
  }

  /// Creates an approximation of a heart at a 45º angle with a circle above
  /// with each component values off-by=one when compared to reference image.
  static var largeHeartOffByOne: CGImage {
    let bytesPerRow = largeHeartDimension * 4
    let dataCount = largeHeartDimension * bytesPerRow
    let data = UnsafeMutablePointer<UInt8>.allocate(capacity: dataCount)
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let context = CGContext(
      data:               data,
      width:              largeHeartDimension,
      height:             largeHeartDimension,
      bitsPerComponent:   8,
      bytesPerRow:        largeHeartDimension * 4,
      space:              space,
      bitmapInfo:         CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.setFillColor(CGColor.black)
    context.fill(CGRect(x: 0,y: 0,width: largeHeartDimension,height: largeHeartDimension))
    context.setFillColor(CGColor.white)
    context.addPath(CGPath.heart)
    context.drawPath(using: .fill)

    let medianData = UInt8.max / 2

    for i in 0..<dataCount {

      if data[i] > medianData {
        data[i] = data[i] - 1
      }
      else {
        data[i] = data[i] + 1
      }
    }

    return context.makeImage()!
  }
}
#endif

#if os(macOS)
extension NSImage {

  /// Creates an approximation of a heart at a 45º angle with a circle above.
  static var heart: NSImage {

    return NSImage(cgImage: CGImage.heart, size: NSZeroSize)
  }

  /// Creates an approximation of a heart at a 45º angle with a circle above
  /// with each component values off-by-one when compared to reference image.
  static var heartOffByOne: NSImage {

    return NSImage(cgImage: CGImage.heartOffByOne, size: NSZeroSize)
  }

  /// Creates an approximation of a heart at a 45º angle with a circle above.
  static var largeHeart: NSImage {

    return NSImage(cgImage: CGImage.largeHeart, size: NSZeroSize)
  }

  /// Creates an approximation of a heart at a 45º angle with a circle above
  /// with each component values off-by-one when compared to reference image.
  static var largeHeartOffByOne: NSImage {

    return NSImage(cgImage: CGImage.largeHeartOffByOne, size: NSZeroSize)
  }
}
#endif

#if os(iOS) || os(tvOS)
extension UIImage {

  /// Creates an approximation of a heart at a 45º angle with a circle above.
  static var heart: UIImage {

    return UIImage(cgImage: CGImage.heart)
  }

  /// Creates an approximation of a heart at a 45º angle with a circle above
  /// with each component values off-by-one when compared to reference image.
  static var heartOffByOne: UIImage {

    return UIImage(cgImage: CGImage.heartOffByOne)
  }

  /// Creates an approximation of a heart at a 45º angle with a circle above.
  static var largeHeart: UIImage {

    return UIImage(cgImage: CGImage.largeHeart)
  }

  /// Creates an approximation of a heart at a 45º angle with a circle above
  /// with each component values off-by-one when compared to reference image.
  static var largeHeartOffByOne: UIImage {

    return UIImage(cgImage: CGImage.largeHeartOffByOne)
  }
}
#endif
