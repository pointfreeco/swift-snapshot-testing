#if os(macOS)
  import Cocoa
  import XCTest

  extension NSImage: Diffable {
    public static var diffableFileExtension: String? {
      return "png"
    }

    public static func fromDiffableData(_ data: Data) -> Self {
      return self.init(data: data)!
    }

    public var diffableData: Data {
      let scale = NSScreen.main!.backingScaleFactor
      self.size = .init(width: self.size.width * 2.0 / scale, height: self.size.height * 2.0 / scale)
      let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil)!
      let rep = NSBitmapImageRep(cgImage: cgImage)
      rep.size = self.size
      let data = rep.representation(using: .png, properties: [:])!
      return data
    }

    public func diff(from other: NSImage) -> Bool {
      let bitmapInfo = NSImage(data: self.diffableData)!
        .cgImage(forProposedRect: nil, context: nil, hints: nil)!
        .bitmapInfo
      return bitmapInfo
        != other.cgImage(forProposedRect: nil, context: nil, hints: nil)!.bitmapInfo
    }

    public func diff(with other: NSImage) -> [XCTAttachment] {
      let maxSize = CGSize(
        width: max(self.size.width, other.size.width),
        height: max(self.size.height, other.size.height)
      )

      let reference = XCTAttachment(image: other)
      reference.name = "reference"

      let failure = XCTAttachment(image: self)
      failure.name = "failure"

      let image = NSImage(size: maxSize)
      image.lockFocus()
      let context = NSGraphicsContext.current!.cgContext
      self.draw(in: .init(origin: .zero, size: self.size))
      context.setAlpha(0.5)
      context.beginTransparencyLayer(auxiliaryInfo: nil)
      other.draw(in: .init(origin: .zero, size: other.size))
      context.setBlendMode(.difference)
      context.fill(.init(origin: .zero, size: self.size))
      context.endTransparencyLayer()
      image.unlockFocus()
      let diff = XCTAttachment(image: image)
      diff.name = "difference"

      return [reference, failure, diff]
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
      return NSImage(data: self.dataWithPDF(inside: self.bounds))!
    }
  }

  extension NSViewController: Snapshot {
    public var snapshotFormat: NSImage {
      return self.view.snapshotFormat
    }
  }
#endif
