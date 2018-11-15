#if os(iOS) || os(tvOS)
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

extension Strategy where Snapshottable == UIImage, Format == UIImage {
  static var image: Strategy {
    return .image(precision: 1)
  }

  static func image(precision: Float) -> Strategy {
    return .init(
      pathExtension: "png",
      diffable: .init(
        to: { $0.pngData()! },
        fro: { UIImage(data: $0, scale: UIScreen.main.scale)! }
      ) { old, new in
        guard !compare(old, new, precision: precision) else { return nil }
        let difference = diff(old, new)
        let message = new.size == old.size
          ? "Expected snapshot to match reference"
          : "Expected snapshot@\(new.size) to match reference@\(old.size)"
        return (
          message,
          [
            .init(image: old, name: "reference"),
            .init(image: new, name: "failure"),
            .init(image: difference, name: "difference")
          ]
        )
      }
    )
  }
}

extension UIImage: DefaultSnapshottable {
  public static let defaultStrategy: SimpleStrategy = .image
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
  let minBytesPerRow = min(oldCgImage.bytesPerRow, newCgImage.bytesPerRow)
  let byteCount = minBytesPerRow * oldCgImage.height
  var oldBytes = [UInt8](repeating: 0, count: byteCount)
  guard let oldContext = context(for: oldCgImage, data: &oldBytes) else { return false }
  guard let newContext = context(for: newCgImage) else { return false }
  guard let oldData = oldContext.data else { return false }
  guard let newData = newContext.data else { return false }
  if memcmp(oldData, newData, byteCount) == 0 { return true }
  let newer = UIImage(data: new.pngData()!)!
  guard let newerCgImage = newer.cgImage else { return false }
  var newerBytes = [UInt8](repeating: 0, count: byteCount)
  guard let newerContext = context(for: newerCgImage, data: &newerBytes) else { return false }
  guard let newerData = newerContext.data else { return false }
  if memcmp(oldData, newerData, byteCount) == 0 { return true }
  if precision >= 1 { return false }
  var differentPixelCount = 0
  let threshold = 1 - precision
  for byte in 0..<byteCount {
    if oldBytes[byte] != newerBytes[byte] { differentPixelCount += 1 }
    if Float(differentPixelCount) / Float(byteCount) > threshold { return false}
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

private func diff(_ old: UIImage, _ new: UIImage) -> UIImage {
  let oldCiImage = CIImage(cgImage: old.cgImage!)
  let newCiImage = CIImage(cgImage: new.cgImage!)
  let differenceFilter = CIFilter(name: "CIDifferenceBlendMode")!
  differenceFilter.setValue(oldCiImage, forKey: kCIInputImageKey)
  differenceFilter.setValue(newCiImage, forKey: kCIInputBackgroundImageKey)
  let differenceCiImage = differenceFilter.outputImage!
  let context = CIContext()
  let differenceCgImage = context.createCGImage(differenceCiImage, from: differenceCiImage.extent)!
  return UIImage(cgImage: differenceCgImage)
}
#endif
