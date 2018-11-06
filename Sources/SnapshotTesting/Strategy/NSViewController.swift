#if os(macOS)
import Cocoa

extension Strategy where A == NSViewController, B == NSImage {
  public static var image: Strategy {
    return .image(precision: 1)
  }

  public static func image(precision: Float) -> Strategy {
    return Strategy<NSView, NSImage>.image(precision: precision).pullback { $0.view }
  }
}

extension Strategy where A == NSViewController, B == String {
  public static var recursiveDescription: Strategy {
    return Strategy<NSView, String>.recursiveDescription.pullback { $0.view }
  }
}

extension NSViewController: DefaultDiffable {
  public static let defaultStrategy: Strategy<NSViewController, NSImage> = .image
}
#endif
