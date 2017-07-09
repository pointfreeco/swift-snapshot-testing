import UIKit
import XCTest

extension Data: Diffable {
  public static var diffableFileExtension: String? {
    return nil
  }

  public var diffableData: Data {
    return self
  }

  public func diff(comparing other: Data) -> XCTAttachment? {
    return nil
  }
}

extension Data: Snapshot {
  public var snapshotFormat: Data {
    return self
  }
}

extension String: Diffable {
  public static var diffableFileExtension: String? {
    return "txt"
  }

  public var diffableData: Data {
    return self.data(using: .utf8)!
  }

  public func diff(comparing other: Data) -> XCTAttachment? {
    return nil
  }
}

extension String: Snapshot {
  public var snapshotFormat: String {
    return self
  }
}

extension UIImage: Diffable {
  public static var diffableFileExtension: String? {
    return "png"
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
    self.draw(in: CGRect(origin: .zero, size: self.size))
    context.setAlpha(0.5)
    context.beginTransparencyLayer(auxiliaryInfo: nil)
    existing.draw(in: CGRect(origin: .zero, size: existing.size))
    context.setBlendMode(.difference)
    context.setFillColor(UIColor.white.cgColor)
    context.fill(CGRect(origin: .zero, size: self.size))
    context.endTransparencyLayer()
    let image = UIGraphicsGetImageFromCurrentImageContext()!
    return XCTAttachment(image: image)
  }
}

extension UIImage: Snapshot {
  public var snapshotFormat: Data {
    return self.diffableData
  }
}
