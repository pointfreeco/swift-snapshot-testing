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
  public static var recursiveDescription: Strategy<NSView, String> {
    return SimpleStrategy<String>.lines.pullback { view in
      return purgePointers(
        view.perform(Selector(("_subtreeDescription"))).retain().takeUnretainedValue()
          as! String
      )
    }
  }
}

extension NSViewController: DefaultDiffable {
  public static let defaultStrategy: Strategy<NSViewController, NSImage> = .viewController
}
#endif
