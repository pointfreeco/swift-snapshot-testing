#if os(macOS)
import Cocoa

extension Strategy where Snapshottable == NSViewController, Format == NSImage {
  public static var image: Strategy {
    return .image(precision: 1)
  }

  public static func image(precision: Float) -> Strategy {
    return .image(precision: precision, size: nil)
  }

  public static func image(precision: Float = 1, size: CGSize) -> Strategy {
    return .image(precision: precision, size: .some(size))
  }

  private static func image(precision: Float, size: CGSize?) -> Strategy {
    return Strategy<NSView, NSImage>.image(precision: precision, size: size).pullback { $0.view }
  }
}

extension Strategy where Snapshottable == NSViewController, Format == String {
  public static var recursiveDescription: Strategy {
    return Strategy<NSView, String>.recursiveDescription.pullback { $0.view }
  }
}
#endif
