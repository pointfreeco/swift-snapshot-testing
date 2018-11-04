#if os(macOS)
import Cocoa

extension Strategy where A == NSViewController, B == NSImage {
  public static var viewController: Strategy {
    return .viewController(precision: 1)
  }

  public static func viewController(precision: Float) -> Strategy {
    return Strategy<NSView, NSImage>.view(precision: precision).pullback { $0.view }
  }
}

extension Strategy where A == NSViewController, B == String {
  public static var recursiveDescription: Strategy {
    return Strategy<NSView, String>.recursiveDescription.pullback { $0.view }
  }
}

extension NSViewController: DefaultDiffable {
  public static let defaultStrategy: Strategy<NSViewController, NSImage> = .viewController
}
#endif
