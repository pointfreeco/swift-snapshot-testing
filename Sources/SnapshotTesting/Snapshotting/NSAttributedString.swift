#if canImport(Cocoa)
import Cocoa

extension Snapshotting where Value == NSAttributedString, Format == NSImage {
  public static func image(precision: Float = 1, maxWidth: CGFloat) -> Snapshotting {
    return Snapshotting<NSView, NSImage>.image(precision: precision).pullback { attributedString in
      let label = NSTextField()
      label.attributedStringValue = attributedString
      label.backgroundColor = .white
      label.isBezeled = false
      label.isEditable = false
      label.preferredMaxLayoutWidth = maxWidth
      label.frame.size = label.fittingSize
      return label
    }
  }
}
#elseif canImport(UIKit)
import UIKit

extension Snapshotting where Value == NSAttributedString, Format == UIImage {
  public static func image(precision: Float = 1, maxWidth: CGFloat) -> Snapshotting {
    return Snapshotting<UIView, UIImage>.image(precision: precision).pullback { attributedString in
      let label = UILabel()
      label.attributedText = attributedString
      label.backgroundColor = .white
      label.numberOfLines = 0
      label.frame.size = label.systemLayoutSizeFitting(
        CGSize(width: maxWidth, height: 0),
        withHorizontalFittingPriority: .defaultHigh,
        verticalFittingPriority: .defaultLow
      )
      return label
    }
  }
}
#endif
