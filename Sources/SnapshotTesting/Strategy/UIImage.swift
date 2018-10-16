#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
import XCTest

extension Attachment {
  public init(image: UIImage, name: String? = nil) {
    #if Xcode
    self.rawValue = XCTAttachment(image: image)
    self.rawValue.name = name
    #endif
  }
}

extension Strategy {
  static var image: SimpleStrategy<UIImage> {
    return .image(precision: 1)
  }

  static func image(precision: Float) -> SimpleStrategy<UIImage> {
    return .init(
      pathExtension: "png",
      diffable: .init(
        to: { UIImagePNGRepresentation($0)! },
        fro: { UIImage(data: $0, scale: UIScreen.main.scale)! }
      ) { old, new in
        guard !compare(old, new, precision: precision) else { return nil }

        let maxSize = CGSize(
          width: max(old.size.width, new.size.width),
          height: max(old.size.height, new.size.height)
        )

        UIGraphicsBeginImageContextWithOptions(maxSize, true, 0)
        defer { UIGraphicsEndImageContext() }
        let context = UIGraphicsGetCurrentContext()!
        old.draw(in: .init(origin: .zero, size: old.size))
        context.setAlpha(0.5)
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        new.draw(in: .init(origin: .zero, size: new.size))
        context.setBlendMode(.difference)
        context.setFillColor(UIColor.white.cgColor)
        context.fill(.init(origin: .zero, size: maxSize))
        context.endTransparencyLayer()
        let diff = UIGraphicsGetImageFromCurrentImageContext()!

        return (
          "Expected image@\(new.size) to match image@\(old.size)",
          [
            .init(image: old, name: "reference"),
            .init(image: new, name: "failure"),
            .init(image: diff, name: "difference")
          ]
        )
      }
    )
  }
}

extension UIImage: DefaultDiffable {
  public static let defaultStrategy: SimpleStrategy<UIImage> = .image
}

private func compare(_ old: UIImage, _ new: UIImage, precision: Float) -> Bool {
  guard let oldCgImage = old.cgImage else { return false }
  guard let newCgImage = new.cgImage else { return false }
  guard oldCgImage.width != 0 else { return false }
  guard newCgImage.width != 0 else { return false }
  guard oldCgImage.width == newCgImage.width else { return false }
  guard oldCgImage.height != 0 else { return false }
  guard newCgImage.height != 0 else { return false }
  guard oldCgImage.height == newCgImage.height else { return false }
  let byteCount = oldCgImage.height * oldCgImage.width * 4
  var oldBytes = [UInt8](repeating: 0, count: byteCount)
  guard let oldContext = context(for: oldCgImage, data: &oldBytes) else { return false }
  guard let newContext = context(for: newCgImage) else { return false }
  guard let oldData = oldContext.data else { return false }
  guard let newData = newContext.data else { return false }
  if memcmp(oldData, newData, byteCount) == 0 { return true }
  let newer = UIImage(data: UIImagePNGRepresentation(new)!)!
  guard let newerCgImage = newer.cgImage else { return false }
  var newerBytes = [UInt8](repeating: 0, count: byteCount)
  guard let newerContext = context(for: newerCgImage, data: &newerBytes) else { return false }
  guard let newerData = newerContext.data else { return false }
  if memcmp(oldData, newerData, byteCount) == 0 { return true }
  var differentPixelCount = 0
  let threshold = 1 - precision
  for x in 1...oldCgImage.width {
    for y in 1...oldCgImage.height {
      if oldBytes[x + x * y] != newerBytes[x + x * y] { differentPixelCount += 1 }
      if Float(differentPixelCount) / Float(byteCount) > threshold { return false}
    }
  }
  return true
}

private func context(for cgImage: CGImage, data: UnsafeMutableRawPointer? = nil) -> CGContext? {
  guard
    let space = cgImage.colorSpace,
    let context = CGContext(
      data: data,
      width: cgImage.width,
      height: cgImage.height,
      bitsPerComponent: cgImage.bitsPerComponent,
      bytesPerRow: cgImage.bytesPerRow,
      space: space,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
    else { return nil }

  context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
  return context
}
#endif
