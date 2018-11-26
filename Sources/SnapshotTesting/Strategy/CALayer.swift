#if os(macOS)
import Cocoa

extension Strategy where Snapshottable == CALayer, Format == NSImage {
  public static var image: Strategy {
    return .image(precision: 1)
  }

  public static func image(precision: Float) -> Strategy {
    return SimpleStrategy.image(precision: precision).pullback { layer in
      let image = NSImage(size: layer.bounds.size)
      image.lockFocus()
      let context = NSGraphicsContext.current!.cgContext
      layer.setNeedsLayout()
      layer.layoutIfNeeded()
      layer.render(in: context)
      image.unlockFocus()
      return image
    }
  }
}

extension CALayer: DefaultSnapshottable {
  public static let defaultStrategy: Strategy<CALayer, NSImage> = .image
}
#elseif os(iOS) || os(tvOS)
import UIKit

extension Strategy where Snapshottable == CALayer, Format == UIImage {
  public static var image: Strategy {
    return .image()
  }

  public static func image(precision: Float = 1, traits: UITraitCollection = .unspecified)
    -> Strategy {
      return SimpleStrategy.image(precision: precision).pullback { layer in
        layer.image(for: traits)
      }
  }
}

extension CALayer {
  func image(for traits: UITraitCollection) -> UIImage {
    let renderer: UIGraphicsImageRenderer
    if #available(iOS 11.0, *) {
      renderer = UIGraphicsImageRenderer(size: self.bounds.size, format: .init(for: traits))
    } else {
      renderer = UIGraphicsImageRenderer(size: self.bounds.size)
    }
    return renderer.image { context in
      self.setNeedsLayout()
      self.layoutIfNeeded()
      self.render(in: context.cgContext)
    }
  }
}

extension CALayer: DefaultSnapshottable {
  public static let defaultStrategy: Strategy<CALayer, UIImage> = .image
}
#endif
