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
    return .init(
      pathExtension: "png",
      diffable: .init(to: { NSImagePNGRepresentation($0)! }, fro: { NSImage(data: $0)! }) { old, new in
        guard
          let oldRep = old.representations.first as? NSBitmapImageRep
          else { return ("Couldn't load reference image data", []) }
        guard
          let newRep = NSImagePNGRepresentation(new)
            .flatMap(NSImage.init(data:))?.representations.first as? NSBitmapImageRep
          else { return ("Couldn't load new image data", []) }

        guard !bitmapEqual(oldRep, newRep) else { return nil }

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

        return (
          "Expected image@\(new.size) to match image@\(old.size)",
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

private func bitmapEqual(_ lhs: NSBitmapImageRep, _ rhs: NSBitmapImageRep) -> Bool {
  guard
    lhs.pixelsWide == rhs.pixelsWide,
    lhs.pixelsHigh == rhs.pixelsHigh
    else { return false }

  for x in 0..<lhs.pixelsWide {
    for y in 0..<lhs.pixelsHigh {
      if lhs.colorAt(x: x, y: y) != rhs.colorAt(x: x, y: y) {
        return false
      }
    }
  }

  return true
}
#endif
