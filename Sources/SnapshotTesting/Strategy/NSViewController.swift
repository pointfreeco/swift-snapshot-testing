#if os(macOS)
import Cocoa

extension Strategy {
  public static var viewController: Strategy<NSViewController, NSImage> {
    return .viewController(precision: 1)
  }

  public static func viewController(precision: Float) -> Strategy<NSViewController, NSImage> {
    return Strategy.view(precision: precision).contramap { $0.view }
  }
}

extension NSViewController: DefaultDiffable {
  public static let defaultStrategy: Strategy<NSViewController, NSImage> = .viewController
}
#endif
