#if os(macOS)
import Cocoa
import XCTest

extension Attachment {
  public init(image: NSImage, name: String? = nil) {
    #if Xcode
    self.rawValue = XCTAttachment(image: image)
    self.rawValue.name = name
    #endif
  }
}

extension Strategy {
  public static var image: SimpleStrategy<NSImage> {
    return .image(precision: 1)
  }

  public static func image(precision: Float) -> SimpleStrategy<NSImage> {
    return .init(
      pathExtension: "png",
      diffable: .init(
        to: { NSImagePNGRepresentation($0)! },
        fro: { NSImage(data: $0)! }
      ) { old, new in
        guard !compare(old, new, precision: precision) else { return nil }

        let maxSize = CGSize(
          width: max(old.size.width, new.size.width),
          height: max(old.size.height, new.size.height)
        )
        let diff = NSImage(size: maxSize)
        diff.lockFocus()
        guard let context = NSGraphicsContext.current?.cgContext else {
          return ("Couldn't acquire a graphics context", [])
        }
        old.draw(in: .init(origin: .zero, size: old.size))
        context.setAlpha(0.5)
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        new.draw(in: .init(origin: .zero, size: new.size))
        context.setBlendMode(.difference)
        context.fill(.init(origin: .zero, size: maxSize))
        context.endTransparencyLayer()
        diff.unlockFocus()
        let message = new.size == old.size
          ? "Expected images to match"
          : "Expected image@\(new.size) to match image@\(old.size)"
        return (
          message,
          [Attachment(image: old), Attachment(image: new), Attachment(image: diff)]
        )
      }
    )
  }
}

extension NSImage: DefaultDiffable {
  public static let defaultStrategy: SimpleStrategy<NSImage> = .image
}

private func NSImagePNGRepresentation(_ image: NSImage) -> Data? {
  guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
  let rep = NSBitmapImageRep(cgImage: cgImage)
  rep.size = image.size
  return rep.representation(using: .png, properties: [:])
}

private func compare(_ old: NSImage, _ new: NSImage, precision: Float) -> Bool {
  guard let oldCgImage = old.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return false }
  guard let newCgImage = new.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return false }
  guard oldCgImage.width != 0 else { return false }
  guard newCgImage.width != 0 else { return false }
  guard oldCgImage.width == newCgImage.width else { return false }
  guard oldCgImage.height != 0 else { return false }
  guard newCgImage.height != 0 else { return false }
  guard oldCgImage.height == newCgImage.height else { return false }
  guard let oldContext = context(for: oldCgImage) else { return false }
  guard let newContext = context(for: newCgImage) else { return false }
  guard let oldData = oldContext.data else { return false }
  guard let newData = newContext.data else { return false }
  let byteCount = oldContext.height * oldContext.bytesPerRow
  if memcmp(oldData, newData, byteCount) == 0 { return true }
  let newer = NSImage(data: NSImagePNGRepresentation(new)!)!
  guard let newerCgImage = newer.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return false }
  guard let newerContext = context(for: newerCgImage) else { return false }
  guard let newerData = newerContext.data else { return false }
  if memcmp(oldData, newerData, byteCount) == 0 { return true }
  let oldRep = NSBitmapImageRep(cgImage: oldCgImage)
  let newRep = NSBitmapImageRep(cgImage: newerCgImage)
  var oldPixel: Int = 0
  var newPixel: Int = 0
  var differentPixelCount = 0
  let pixelCount = oldRep.pixelsWide * oldRep.pixelsHigh
  let threshold = 1 - precision
  for x in 0..<oldRep.pixelsWide {
    for y in 0..<oldRep.pixelsHigh {
      oldRep.getPixel(&oldPixel, atX: x, y: y)
      newRep.getPixel(&newPixel, atX: x, y: y)
      if oldPixel != newPixel { differentPixelCount += 1 }
      if Float(differentPixelCount) / Float(pixelCount) > threshold { return false}
    }
  }
  return true
}

private func context(for cgImage: CGImage) -> CGContext? {
  guard
    let space = cgImage.colorSpace,
    let context = CGContext(
      data: nil,
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
