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
extension Strategy where A == NSView, B == NSImage {
  public static var image: Strategy {
    return .image(precision: 1)
  }

  public static func image(precision: Float) -> Strategy {
    return Strategy<NSImage, NSImage>.image(precision: precision).asyncPullback { view in
      view.snapshot ?? Async { callback in
        addImagesForRenderedViews(view).sequence().run { views in
          let image = NSImage(data: view.dataWithPDF(inside: view.bounds))!
          image.size = .init(width: image.size.width, height: image.size.height)
          callback(image)
          views.forEach { $0.removeFromSuperview() }
        }
      }
    }
  }
}

extension Strategy where A == NSView, B == String {
  public static var recursiveDescription: Strategy<NSView, String> {
    return SimpleStrategy.lines.pullback { view in
      return purgePointers(
        view.perform(Selector(("_subtreeDescription"))).retain().takeUnretainedValue()
          as! String
      )
    }
  }
}

extension NSView: DefaultDiffable {
  public static let defaultStrategy: Strategy<NSView, NSImage> = .image
}
#elseif os(iOS) || os(tvOS)
extension Strategy where A == UIView, B == UIImage {
  public static var image: Strategy {
    return .image(precision: 1)
  }

  public static func image(precision: Float) -> Strategy {
    return SimpleStrategy.image(precision: precision).asyncPullback { view in
      view.snapshot ?? Async { callback in
        addImagesForRenderedViews(view).sequence().run { views in
          Strategy<CALayer, UIImage>.image.snapshotToDiffable(view.layer).run { image in
            callback(image)
            views.forEach { $0.removeFromSuperview() }
          }
        }
      }
    }
  }
}

extension Strategy where A == UIView, B == String {
  public static var recursiveDescription: Strategy<UIView, String> {
    return SimpleStrategy.lines.pullback { view in
      return purgePointers(
        view.perform(Selector(("recursiveDescription"))).retain().takeUnretainedValue()
          as! String
      )
    }
  }
}

extension UIView: DefaultDiffable {
  public static let defaultStrategy: Strategy<UIView, UIImage> = .image
}
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
            fatalError("Taking WKWebView snapshots requires macOS 10.13 or greater")
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
    webView.evaluateJavaScript("[document.body.clientWidth, document.body.clientHeight]") { result, error in
      if let xs = result as? [Int] {
        webView.frame.size = .init(width: xs[0], height: xs[1])
      }
      self.didFinish()
    }
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
