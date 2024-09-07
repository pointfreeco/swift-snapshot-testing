import Foundation
import ImageSerializer

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct PNGCoder {
  static func encodeImage(_ image: SnapImage) -> Data? {
#if !os(macOS)
        return image.pngData()
#else
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
          return nil
        }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .png, properties: [:])
#endif
  }

  static func decodeImage(_ data: Data) -> SnapImage? {
#if !os(macOS)
        return UIImage(data: data)
#else
        return NSImage(data: data)
#endif
  }
}

extension ImageSerializer {
  package static var png: Self {
    ImageSerializer(
      encodeImage: PNGCoder.encodeImage,
      decodeImage: PNGCoder.decodeImage
    )
  }
}
