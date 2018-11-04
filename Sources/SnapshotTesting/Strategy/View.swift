#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
import SceneKit
import SpriteKit
import WebKit
import WKSnapshotConfigurationShim
#if os(macOS)
import Cocoa
#elseif os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#endif

#if os(macOS)
extension Strategy where A == NSView, B == NSImage {
  public static var view: Strategy {
    return .view(precision: 1)
  }

  public static func view(precision: Float) -> Strategy {
    return Strategy<NSImage, NSImage>.image(precision: precision).asyncPullback { view in
      return view.snapshot ?? Async { callback in
        addImagesForRenderedViews(view).sequence().run { views in
          let image = NSImage(data: view.dataWithPDF(inside: view.bounds))!
          let scale = NSScreen.main!.backingScaleFactor
          image.size = .init(width: image.size.width * 2.0 / scale, height: image.size.height * 2.0 / scale)
          callback(image)
          views.forEach { $0.removeFromSuperview() }
        }
      }
    }
  }
}

extension Strategy where A == NSView, B == String {
  public static var recursiveDescription: Strategy<NSView, String> {
    return SimpleStrategy<String>.lines.pullback { view in
      return purgePointers(
        view.perform(Selector(("_subtreeDescription"))).retain().takeUnretainedValue()
          as! String
      )
    }
  }
}

extension NSView: DefaultDiffable {
  public static let defaultStrategy: Strategy<NSView, NSImage> = .view
}
#elseif os(iOS) || os(tvOS) || os(watchOS)
extension Strategy where A == UIView, B == UIImage {
  public static var view: Strategy {
    return self.view(precision: 1)
  }

  public static func view(precision: Float) -> Strategy {
    return SimpleStrategy<UIImage>.image(precision: precision).asyncPullback { view in
      view.snapshot ?? Async { callback in
        addImagesForRenderedViews(view).sequence().run { views in
          Strategy<CALayer, UIImage>.layer.snapshotToDiffable(view.layer).run { image in
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
    return SimpleStrategy<String>.lines.pullback { view in
      return purgePointers(
        view.perform(Selector(("recursiveDescription"))).retain().takeUnretainedValue()
          as! String
      )
    }
  }
}

extension UIView: DefaultDiffable {
  public static let defaultStrategy: Strategy<UIView, UIImage> = .view
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
            #elseif os(iOS) || os(tvOS) || os(watchOS)
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
    #if os(iOS) || os(tvOS) || os(watchOS)
    if let glkView = self as? GLKView {
      return Async(value: glkView.snapshot)
    }
    #endif
    if let scnView = self as? SCNView {
      return Async(value: scnView.snapshot())
    } else if let skView = self as? SKView {
      if #available(macOS 10.11, *) {
        let cgImage = skView.texture(from: skView.scene!)!.cgImage()
        #if os(macOS)
        let image = Image(cgImage: cgImage, size: skView.bounds.size)
        #elseif os(iOS) || os(tvOS) || os(watchOS)
        let image = Image(cgImage: cgImage)
        #endif
        return Async(value: image)
      } else {
        fatalError("Taking SKView snapshots requires macOS 10.11 or greater")
      }
    } else if let wkWebView = self as? WKWebView {
      return Async<Image> { callback in
        let delegate = NavigationDelegate()
        let work = {
          #if os(macOS)
          if self.superview == nil {
            let window = ScaledWindow()
            window.contentView = NSView()
            window.contentView?.addSubview(wkWebView)
            window.makeKey()
          }
          #endif

          if #available(macOS 10.13, *) {
            wkWebView.takeSnapshot(with: nil) { image, _ in
              _ = delegate
              callback(image!)
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
    } else {
      return nil
    }
  }
}

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

#if os(macOS)
import Cocoa

fileprivate final class ScaledWindow: NSWindow {
  override var backingScaleFactor: CGFloat {
    return 2
  }
}
#endif
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
