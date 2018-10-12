#if os(macOS)
import Cocoa

extension Strategy {
  public static var viewController: Strategy<NSViewController, NSImage> {
    return Strategy.view.contramap { $0.view }
  }
}

extension NSViewController: DefaultDiffable {
  public static let defaultStrategy: Strategy<NSViewController, NSImage> = .viewController
}
#endif
