#if os(iOS)
  import UIKit
  import XCTest

  extension UIImage: Diffable {
    public static var diffableFileExtension: String? {
      return "png"
    }

    public static func fromDiffableData(_ data: Data) -> Self {
      return self.init(data: data, scale: 2.0)!
    }

    public var diffableData: Data {
      return UIImagePNGRepresentation(self)!
    }

    public func diff(with other: UIImage) -> [XCTAttachment] {
      let maxSize = CGSize(
        width: max(self.size.width, other.size.width),
        height: max(self.size.height, other.size.height)
      )

      let reference = XCTAttachment(image: other)
      reference.name = "reference"

      let failure = XCTAttachment(image: self)
      failure.name = "failure"

      UIGraphicsBeginImageContextWithOptions(maxSize, true, 0)
      defer { UIGraphicsEndImageContext() }
      let context = UIGraphicsGetCurrentContext()!
      self.draw(in: .init(origin: .zero, size: self.size))
      context.setAlpha(0.5)
      context.beginTransparencyLayer(auxiliaryInfo: nil)
      other.draw(in: .init(origin: .zero, size: other.size))
      context.setBlendMode(.difference)
      context.setFillColor(UIColor.white.cgColor)
      context.fill(.init(origin: .zero, size: self.size))
      context.endTransparencyLayer()
      let image = UIGraphicsGetImageFromCurrentImageContext()!
      let diff = XCTAttachment(image: image)
      diff.name = "difference"

      return [reference, failure, diff]
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
