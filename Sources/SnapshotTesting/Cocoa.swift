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
      let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil)!
      let rep = NSBitmapImageRep(cgImage: cgImage)
      rep.size = self.size
      let data = rep.representation(using: .png, properties: [:])!
      return data
    }

    public func diff(comparing other: Data) -> XCTAttachment? {
      let existing = NSImage(data: other)!

      let maxSize = CGSize(
        width: max(self.size.width, existing.size.width),
        height: max(self.size.height, existing.size.height)
      )

      let image = NSImage(size: maxSize)
      image.lockFocus()
      let context = NSGraphicsContext.current!.cgContext
      self.draw(in: .init(origin: .zero, size: self.size))
      context.setAlpha(0.5)
      context.beginTransparencyLayer(auxiliaryInfo: nil)
      existing.draw(in: .init(origin: .zero, size: existing.size))
      context.setBlendMode(.difference)
      context.fill(.init(origin: .zero, size: self.size))
      context.endTransparencyLayer()
      image.unlockFocus()
      return XCTAttachment(image: image)
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
