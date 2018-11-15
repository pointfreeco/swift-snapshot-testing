#if os(iOS) || os(macOS) || os(tvOS)
#if os(macOS)
import Cocoa
#endif
import SceneKit
import SpriteKit
#if os(iOS) || os(tvOS)
import UIKit
#endif
#if os(iOS) || os(macOS)
import WebKit
#endif

#if os(macOS)
extension Strategy where Snapshottable == NSView, Format == NSImage {
  public static var image: Strategy {
    return .image(precision: 1, size: nil)
  }

  public static func image(precision: Float) -> Strategy {
    return .image(precision: precision, size: nil)
  }

  public static func image(precision: Float = 1, size: CGSize) -> Strategy {
    return .image(precision: precision, size: .some(size))
  }

  static func image(precision: Float, size: CGSize?) -> Strategy {
    return Strategy<NSImage, NSImage>.image(precision: precision).asyncPullback { view in
      let initialSize = view.frame.size
      if let size = size { view.frame.size = size }
      guard view.frame.width > 0, view.frame.height > 0 else {
        fatalError("View not renderable to image at size \(view.frame.size)")
      }
      return view.snapshot ?? Async { callback in
        addImagesForRenderedViews(view).sequence().run { views in
          let image = NSImage(data: view.dataWithPDF(inside: view.bounds))!
          image.size = .init(width: image.size.width, height: image.size.height)
          callback(image)
          views.forEach { $0.removeFromSuperview() }
          view.frame.size = initialSize
        }
      }
    }
  }
}

extension Strategy where Snapshottable == NSView, Format == String {
  public static var recursiveDescription: Strategy<NSView, String> {
    return SimpleStrategy.lines.pullback { view in
      return purgePointers(
        view.perform(Selector(("_subtreeDescription"))).retain().takeUnretainedValue()
          as! String
      )
    }
  }
}

extension NSView: DefaultSnapshottable {
  public static let defaultStrategy: Strategy<NSView, NSImage> = .image
}
#elseif os(iOS) || os(tvOS)
extension Strategy where Snapshottable == UIView, Format == UIImage {
  public static var image: Strategy {
    return .image()
  }

  public static func image(
    drawingHierarchyInKeyWindow: Bool = false,
    precision: Float = 1,
    size: CGSize? = nil,
    traits: UITraitCollection = .init()
    )
    -> Strategy {

      return SimpleStrategy.image(precision: precision).asyncPullback { view in
        let size = size ?? view.frame.size
        guard size.width > 0, size.height > 0 else {
          fatalError("View not renderable to image at size \(view.frame.size)")
        }
        view.frame.size = size

        let child = UIViewController()
        child.view.bounds = view.bounds
        child.view.addSubview(view)
        let parent = traitController(for: child, size: size, traits: traits)

        let initialFrame = parent.view.frame
        if drawingHierarchyInKeyWindow, let window = UIApplication.shared.keyWindow, window != view {
          parent.view.frame.origin = CGPoint(x: .max, y: .max)
          window.addSubview(parent.view)
        }
        parent.view.setNeedsLayout()
        parent.view.layoutIfNeeded()
        return parent.view.snapshot ?? Async { callback in
          addImagesForRenderedViews(parent.view).sequence().run { views in
            let cleanup = {
              views.forEach { $0.removeFromSuperview() }
              view.frame = initialFrame
            }
            if drawingHierarchyInKeyWindow, let window = UIApplication.shared.keyWindow, window != view {
              let image = UIGraphicsImageRenderer(size: view.bounds.size).image { context in
                parent.view.drawHierarchy(in: parent.view.bounds, afterScreenUpdates: true)
              }
              callback(image)
              cleanup()
              parent.view.removeFromSuperview()
            } else {
              Strategy<CALayer, UIImage>.image.snapshotToDiffable(parent.view.layer).run { image in
                callback(image)
                cleanup()
              }
            }
          }
        }
      }
  }
}

extension Strategy where Snapshottable == UIView, Format == String {
  public static var recursiveDescription: Strategy<UIView, String> {
    return SimpleStrategy.lines.pullback { view in
      view.setNeedsLayout()
      view.layoutIfNeeded()
      return purgePointers(
        view.perform(Selector(("recursiveDescription"))).retain().takeUnretainedValue()
          as! String
      )
    }
  }
}

extension UIView: DefaultSnapshottable {
  public static let defaultStrategy: Strategy<UIView, UIImage> = .image
}

func traitController(
  for viewController: UIViewController,
  size: CGSize,
  traits: UITraitCollection)
  -> UIViewController
{

  let parent = UIViewController()
  parent.view.backgroundColor = .clear
  parent.view.frame.size = size
  parent.preferredContentSize = parent.view.frame.size
  viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
  viewController.view.frame = parent.view.frame
  parent.view.addSubview(viewController.view)
  parent.addChild(viewController)
  parent.setOverrideTraitCollection(traits, forChild: viewController)
  viewController.didMove(toParent: parent)
  parent.beginAppearanceTransition(true, animated: false)
  parent.endAppearanceTransition()
  return parent
}

extension Strategy where Snapshottable == UIViewController, Format == UIImage {
  public struct Config {
    public enum Orientation {
      case landscape
      case portrait
    }

    public let size: CGSize
    public let traits: UITraitCollection

    public init(size: CGSize, traits: UITraitCollection) {
      self.size = size
      self.traits = traits
    }

    #if os(iOS)
    public static let iPhoneSe = Config.iPhoneSe(.portrait)

    public static func iPhoneSe(_ orientation: Orientation) -> Config {
      let size: CGSize
      switch orientation {
      case .landscape:
        size = .init(width: 568, height: 320)
      case .portrait:
        size = .init(width: 320, height: 568)
      }
      return .init(size: size, traits: .iPhoneSe(orientation))
    }

    public static let iPhone8 = Config.iPhone8(.portrait)

    public static func iPhone8(_ orientation: Orientation) -> Config {
      let size: CGSize
      switch orientation {
      case .landscape:
        size = .init(width: 667, height: 375)
      case .portrait:
        size = .init(width: 375, height: 667)
      }
      return .init(size: size, traits: .iPhone8(orientation))
    }

    public static let iPhone8Plus = Config.iPhone8Plus(.portrait)

    public static func iPhone8Plus(_ orientation: Orientation) -> Config {
      let size: CGSize
      switch orientation {
      case .landscape:
        size = .init(width: 736, height: 414)
      case .portrait:
        size = .init(width: 414, height: 736)
      }
      return .init(size: size, traits: .iPhone8Plus(orientation))
    }

    public static let iPadMini = Config.iPadMini(.landscape)

    public static func iPadMini(_ orientation: Orientation) -> Config {
      let size: CGSize
      switch orientation {
      case .landscape:
        size = .init(width: 1024, height: 768)
      case .portrait:
        size = .init(width: 768, height: 1024)
      }
      return .init(size: size, traits: .iPadMini)
    }

    public static let iPadPro10_5 = Config.iPadPro10_5(.landscape)

    public static func iPadPro10_5(_ orientation: Orientation) -> Config {
      let size: CGSize
      switch orientation {
      case .landscape:
        size = .init(width: 1112, height: 834)
      case .portrait:
        size = .init(width: 834, height: 1112)
      }
      return .init(size: size, traits: .iPadPro10_5)
    }

    public static let iPadPro12_9 = Config.iPadPro12_9(.landscape)

    public static func iPadPro12_9(_ orientation: Orientation) -> Config {
      let size: CGSize
      switch orientation {
      case .landscape:
        size = .init(width: 1366, height: 1024)
      case .portrait:
        size = .init(width: 1024, height: 1366)
      }
      return .init(size: size, traits: .iPadPro12_9)
    }
    #endif
  }
}

#if os(iOS)
extension UITraitCollection {
  public static func iPhoneSe(_ orientation: Strategy<UIViewController, UIImage>.Config.Orientation)
    -> UITraitCollection {
      switch orientation {
      case .landscape:
        return .init(
          traitsFrom: [
            .init(displayScale: 2),
            .init(horizontalSizeClass: .compact),
            .init(verticalSizeClass: .compact),
            .init(userInterfaceIdiom: .phone)
          ]
        )
      case .portrait:
        return .init(
          traitsFrom: [
            .init(displayScale: 2),
            .init(horizontalSizeClass: .compact),
            .init(verticalSizeClass: .regular),
            .init(userInterfaceIdiom: .phone)
          ]
        )
      }
  }

  public static func iPhone8(_ orientation: Strategy<UIViewController, UIImage>.Config.Orientation)
    -> UITraitCollection {
      switch orientation {
      case .landscape:
        return .init(
          traitsFrom: [
            .init(displayScale: 2),
            .init(horizontalSizeClass: .compact),
            .init(verticalSizeClass: .compact),
            .init(userInterfaceIdiom: .phone)
          ]
        )
      case .portrait:
        return .init(
          traitsFrom: [
            .init(displayScale: 2),
            .init(horizontalSizeClass: .compact),
            .init(verticalSizeClass: .regular),
            .init(userInterfaceIdiom: .phone)
          ]
        )
      }
  }

  public static func iPhone8Plus(_ orientation: Strategy<UIViewController, UIImage>.Config.Orientation)
    -> UITraitCollection {
      switch orientation {
      case .landscape:
        return .init(
          traitsFrom: [
            .init(displayScale: 3),
            .init(horizontalSizeClass: .regular),
            .init(verticalSizeClass: .compact),
            .init(userInterfaceIdiom: .phone)
          ]
        )
      case .portrait:
        return .init(
          traitsFrom: [
            .init(displayScale: 3),
            .init(horizontalSizeClass: .compact),
            .init(verticalSizeClass: .regular),
            .init(userInterfaceIdiom: .phone)
          ]
        )
      }
  }

  public static let iPadMini = iPad
  public static let iPadPro10_5 = iPad
  public static let iPadPro12_9 = iPad

  private static let iPad = UITraitCollection(
    traitsFrom: [
      .init(displayScale: 2),
      .init(horizontalSizeClass: .regular),
      .init(verticalSizeClass: .regular),
      .init(userInterfaceIdiom: .pad)
    ]
  )
}
#endif
#endif

private func addImagesForRenderedViews(_ view: View) -> [Async<View>] {
  return view.snapshot
    .map { async in
      [
        Async { callback in
          async.run { image in
            let imageView = ImageView()
            imageView.image = image
            imageView.frame = view.frame
            #if os(macOS)
            view.superview?.addSubview(imageView, positioned: .above, relativeTo: view)
            #elseif os(iOS) || os(tvOS)
            view.superview?.insertSubview(imageView, aboveSubview: view)
            #endif
            callback(imageView)
          }
        }
      ]
    }
    ?? view.subviews.flatMap(addImagesForRenderedViews)
}

fileprivate extension View {
  var snapshot: Async<Image>? {
    func inWindow<T>(_ perform: () -> T) -> T {
      #if os(macOS)
      let superview = self.superview
      defer { superview?.addSubview(self) }
      let window = ScaledWindow()
      window.contentView = NSView()
      window.contentView?.addSubview(self)
      window.makeKey()
      #endif
      return perform()
    }
    #if os(iOS) || os(tvOS)
    if let glkView = self as? GLKView {
      return Async(value: inWindow { glkView.snapshot })
    }
    #endif
    if let scnView = self as? SCNView {
      return Async(value: inWindow { scnView.snapshot() })
    } else if let skView = self as? SKView {
      if #available(macOS 10.11, *) {
        let cgImage = inWindow { skView.texture(from: skView.scene!)!.cgImage() }
        #if os(macOS)
        let image = Image(cgImage: cgImage, size: skView.bounds.size)
        #elseif os(iOS) || os(tvOS)
        let image = Image(cgImage: cgImage)
        #endif
        return Async(value: image)
      } else {
        fatalError("Taking SKView snapshots requires macOS 10.11 or greater")
      }
    }
    #if os(iOS) || os(macOS)
    if let wkWebView = self as? WKWebView {
      return Async<Image> { callback in
        let delegate = NavigationDelegate()
        let work = {
          if #available(iOS 11.0, macOS 10.13, *) {
            inWindow {
              wkWebView.takeSnapshot(with: nil) { image, _ in
                _ = delegate
                callback(image!)
              }
            }
          } else {
            #if os(iOS)
            fatalError("Taking WKWebView snapshots requires iOS 11.0 or greater")
            #elseif os(macOS)
            fatalError("Taking WKWebView snapshots requires macOS 10.13 or greater")
            #endif
          }
        }

        if wkWebView.isLoading {
          delegate.didFinish = work
          wkWebView.navigationDelegate = delegate
        } else {
          work()
        }
      }
    }
    #endif
    return nil
  }
}

#if os(iOS) || os(macOS)
private final class NavigationDelegate: NSObject, WKNavigationDelegate {
  var didFinish: () -> Void

  init(didFinish: @escaping () -> Void = {}) {
    self.didFinish = didFinish
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    self.didFinish()
  }
}
#endif

#if os(macOS)
import Cocoa

fileprivate final class ScaledWindow: NSWindow {
  override var backingScaleFactor: CGFloat {
    return 2
  }
}
#endif

fileprivate extension Array {
  func sequence<A>() -> Async<[A]> where Element == Async<A> {
    guard !self.isEmpty else { return Async(value: []) }
    return Async<[A]> { callback in
      var result = [A?](repeating: nil, count: self.count)
      result.reserveCapacity(self.count)
      var count = 0
      zip(self.indices, self).forEach { idx, async in
        async.run {
          result[idx] = $0
          count += 1
          if count == self.count {
            callback(result as! [A])
          }
        }
      }
    }
  }
}
#endif
