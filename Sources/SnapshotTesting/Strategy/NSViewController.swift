#if os(macOS)
import Cocoa

extension Strategy where Snapshottable == NSViewController, Format == NSImage {
  public static var image: Strategy {
    return .image(precision: 1)
  }

  public static func image(precision: Float) -> Strategy {
    return Strategy<NSView, NSImage>.image(precision: precision).pullback { $0.view }
  }
}

extension Strategy where Snapshottable == NSViewController, Format == String {
  public static var recursiveDescription: Strategy {
    return Strategy<NSView, String>.recursiveDescription.pullback { $0.view }
  }
}

extension NSViewController: DefaultSnapshottable {
  public static let defaultStrategy: Strategy<NSViewController, NSImage> = .image
}
#endif
