#if os(macOS)
import Cocoa
import XCTest

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

extension NSImage: Diffable {
  public static let diffablePathExtension = String?.some("png")

  public static func diffableDiff(_ fst: NSImage, _ snd: NSImage) -> (String, [XCTAttachment])? {
    let repA = fst.representations[0] as! NSBitmapImageRep
    let repB = NSImage(data: snd.diffableData)!.representations[0] as! NSBitmapImageRep

    guard !bitmapEqual(repA, repB) else { return nil }

    let maxSize = CGSize(
      width: max(fst.size.width, snd.size.width),
      height: max(fst.size.height, snd.size.height)
    )

    let reference = XCTAttachment(image: fst)
    reference.name = "reference"

    let failure = XCTAttachment(image: snd)
    failure.name = "failure"

    let image = NSImage(size: maxSize)
    image.lockFocus()
    let context = NSGraphicsContext.current!.cgContext
    fst.draw(in: .init(origin: .zero, size: fst.size))
    context.setAlpha(0.5)
    context.beginTransparencyLayer(auxiliaryInfo: nil)
    snd.draw(in: .init(origin: .zero, size: snd.size))
    context.setBlendMode(.difference)
    context.fill(.init(origin: .zero, size: maxSize))
    context.endTransparencyLayer()
    image.unlockFocus()

    let diff = XCTAttachment(image: image)
    diff.name = "difference"

    return ("Expected image@\(snd.size) to match image@\(fst.size)", [reference, failure, diff])
  }

  public static func fromDiffableData(_ diffableData: Data) -> Self {
    return self.init(data: diffableData)!
  }

  public var diffableData: Data {
    let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil)!
    let rep = NSBitmapImageRep(cgImage: cgImage)
    rep.size = self.size
    let data = rep.representation(using: .png, properties: [:])!
    return data
  }

  public var diffableDescription: String? {
    return nil
  }
}

extension CALayer: Snapshot {
  public var snapshotFormat: NSImage {
    let image = NSImage(size: self.bounds.size)
    image.lockFocus()
    let context = NSGraphicsContext.current!.cgContext
    self.render(in: context)
    image.unlockFocus()
    return image
  }
}

extension NSImage: Snapshot {
  public var snapshotFormat: Data {
    return self.diffableData
  }
}

extension NSView: Snapshot {
  public var snapshotFormat: NSImage {
    let image = NSImage(data: self.dataWithPDF(inside: self.bounds))!
    let scale = NSScreen.main!.backingScaleFactor
    image.size = .init(width: image.size.width * 2.0 / scale, height: image.size.height * 2.0 / scale)
    return image
  }
}

extension NSViewController: Snapshot {
  public var snapshotFormat: NSImage {
    return self.view.snapshotFormat
  }
}
#endif
