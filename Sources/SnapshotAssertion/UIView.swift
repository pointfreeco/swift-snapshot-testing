import UIKit

extension UIView: Snapshot {
  public var snapshotFormat: UIImage {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 2.0)
    defer { UIGraphicsEndImageContext() }
    let context = UIGraphicsGetCurrentContext()!
    self.layer.render(in: context)
    return UIGraphicsGetImageFromCurrentImageContext()!
  }
}
