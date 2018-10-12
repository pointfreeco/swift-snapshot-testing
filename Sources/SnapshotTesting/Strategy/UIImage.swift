#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
import XCTest

extension Attachment {
  public init(image: UIImage, name: String? = nil) {
    #if Xcode
    self.rawValue = XCTAttachment(image: image)
    self.rawValue.name = name
    #endif
  }
}

extension Strategy {
  static var image: SimpleStrategy<UIImage> {
    return .init(
      pathExtension: "png",
      diffable: .init(
        to: { UIImagePNGRepresentation($0)! },
        fro: { UIImage(data: $0, scale: UIScreen.main.scale)! }
      ) { old, new in
        guard UIImagePNGRepresentation(old) != UIImagePNGRepresentation(new) else { return nil }

        let maxSize = CGSize(
          width: max(old.size.width, new.size.width),
          height: max(old.size.height, new.size.height)
        )

        UIGraphicsBeginImageContextWithOptions(maxSize, true, 0)
        defer { UIGraphicsEndImageContext() }
        let context = UIGraphicsGetCurrentContext()!
        old.draw(in: .init(origin: .zero, size: old.size))
        context.setAlpha(0.5)
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        new.draw(in: .init(origin: .zero, size: new.size))
        context.setBlendMode(.difference)
        context.setFillColor(UIColor.white.cgColor)
        context.fill(.init(origin: .zero, size: maxSize))
        context.endTransparencyLayer()
        let diff = UIGraphicsGetImageFromCurrentImageContext()!

        return (
          "Expected image@\(new.size) to match image@\(old.size)",
          [
            .init(image: old, name: "reference"),
            .init(image: new, name: "failure"),
            .init(image: diff, name: "difference")
          ]
        )
      }
    )
  }
}

extension UIImage: DefaultDiffable {
  public static let defaultStrategy: SimpleStrategy<UIImage> = .image
}
#endif
