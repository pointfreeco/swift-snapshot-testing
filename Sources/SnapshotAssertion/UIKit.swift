#if os(iOS)
  import UIKit
  import XCTest

  extension UIImage: Diffable {
    public static var diffableFileExtension: String? {
      return "png"
    }

    public static func fromDiffableData(_ data: Data) -> Self {
      return self.init(data: data)!
    }

    public var diffableData: Data {
      return UIImagePNGRepresentation(self)!
    }

    public func diff(comparing other: Data) -> XCTAttachment? {
      let existing = UIImage(data: other, scale: 2.0)!

      let maxSize = CGSize(
        width: max(self.size.width, existing.size.width),
        height: max(self.size.height, existing.size.height)
      )

      UIGraphicsBeginImageContextWithOptions(maxSize, true, 0)
      defer { UIGraphicsEndImageContext() }
      let context = UIGraphicsGetCurrentContext()!
      self.draw(in: .init(origin: .zero, size: self.size))
      context.setAlpha(0.5)
      context.beginTransparencyLayer(auxiliaryInfo: nil)
      existing.draw(in: .init(origin: .zero, size: existing.size))
      context.setBlendMode(.difference)
      context.setFillColor(UIColor.white.cgColor)
      context.fill(.init(origin: .zero, size: self.size))
      context.endTransparencyLayer()
      let image = UIGraphicsGetImageFromCurrentImageContext()!
      return XCTAttachment(image: image)
    }
  }

  extension CALayer: Snapshot {
    public var snapshotFormat: UIImage {
      UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 2.0)
      defer { UIGraphicsEndImageContext() }
      let context = UIGraphicsGetCurrentContext()!
      self.render(in: context)
      return UIGraphicsGetImageFromCurrentImageContext()!
    }
  }

  extension UIImage: Snapshot {
    public var snapshotFormat: Data {
      return self.diffableData
    }
  }

  extension UIView: Snapshot {
    public var snapshotFormat: UIImage {
      return self.layer.snapshotFormat
    }
  }

  extension UIViewController: Snapshot {
    public var snapshotFormat: UIImage {
      return self.view.snapshotFormat
    }
  }
#endif
