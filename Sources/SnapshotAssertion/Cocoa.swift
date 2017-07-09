import Cocoa
import XCTest

#if os(macOS)
  extension NSImage: Diffable {
    public static var diffableFileExtension: String? {
      return "png"
    }

    public static func fromDiffableData(_ data: Data) -> Self {
      return self.init(data: data)!
    }

    public var diffableData: Data {
      return NSBitmapImageRep(data: self.tiffRepresentation!)!.representation(using: .png, properties: [:])!
    }

    public func diff(comparing other: Data) -> XCTAttachment? {
      return nil
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
