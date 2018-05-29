#if os(iOS)
import UIKit
import XCTest

extension UIImage: Diffable {
  public static let diffablePathExtension = String?.some("png")

  public static func diffableDiff(_ fst: UIImage, _ snd: UIImage) -> (String, [XCTAttachment])? {
    guard fst.diffableData != snd.diffableData else { return nil }

    let maxSize = CGSize(
      width: max(fst.size.width, snd.size.width),
      height: max(fst.size.height, snd.size.height)
    )

    let reference = XCTAttachment(image: fst)
    reference.name = "reference"

    let failure = XCTAttachment(image: snd)
    failure.name = "failure"

    UIGraphicsBeginImageContextWithOptions(maxSize, true, 0)
    defer { UIGraphicsEndImageContext() }
    let context = UIGraphicsGetCurrentContext()!
    fst.draw(in: .init(origin: .zero, size: fst.size))
    context.setAlpha(0.5)
    context.beginTransparencyLayer(auxiliaryInfo: nil)
    snd.draw(in: .init(origin: .zero, size: snd.size))
    context.setBlendMode(.difference)
    context.setFillColor(UIColor.white.cgColor)
    context.fill(.init(origin: .zero, size: maxSize))
    context.endTransparencyLayer()
    let image = UIGraphicsGetImageFromCurrentImageContext()!

    let diff = XCTAttachment(image: image)
    diff.name = "difference"

    return ("Expected image@\(snd.size) to match image@\(fst.size)", [reference, failure, diff])
  }

  public static func fromDiffableData(_ diffableData: Data) -> Self {
    return self.init(data: diffableData, scale: UIScreen.main.scale)!
  }

  public var diffableData: Data {
    return UIImagePNGRepresentation(self)!
  }

  public var diffableDescription: String? {
    return nil
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
  public var snapshotFormat: UIImage {
    return self
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
