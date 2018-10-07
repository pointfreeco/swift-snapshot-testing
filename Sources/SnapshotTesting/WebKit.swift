import WebKit
import WKSnapshotConfigurationShim

@available(OSX 10.13, *)
extension Strategy {

  public static var webView: Strategy<WKWebView, NSImage> {

    // ((S') -> Parallel<S>) -> (Strategy<S> -> (Parallel?) Strategy<S'>)

    return Strategy.image.contramap { webView in

//      return { imageCallback in
//        imageCallback(image)
//      }

      if webView.isLoading {
        let sema = DispatchSemaphore(value: 0)
        let delegate = NavigationDelegate { sema.signal() }
        webView.navigationDelegate = delegate
        sema.wait()
      }
      if webView.superview == nil {
        let window = ScaledWindow()
        window.contentView = NSView()
        window.contentView?.addSubview(webView)
        window.makeKey()
      }

      var snapshotImage: NSImage!
      let sema = DispatchSemaphore(value: 0)

      webView.takeSnapshot(with: nil) { image, _ in
        snapshotImage = image
        sema.signal()
      }
      sema.wait()

      return snapshotImage
    }
  }
}


@available(OSX 10.13, *)
extension _Strategy {

  static func webView(devices: [Device], aboveFoldMarker: Bool) -> _Strategy<WKWebView, NSImage> {
  }

  static var _webView: _Strategy<WKWebView, NSImage> {
    return _Strategy._image.transform { webView in
      return Parallel { callback in
        if webView.frame.size == .zero {
          webView.frame.size = .init(width: 800, height: 600)
        }
        
        if webView.isLoading {
          let delegate = NavigationDelegate()
          delegate.didFinish = {
            if webView.superview == nil {
              let window = ScaledWindow()
              window.contentView = NSView()
              window.contentView?.addSubview(webView)
              window.makeKey()
            }
            
            webView.takeSnapshot(with: nil) { image, _ in
              _ = delegate
              callback(image!)
            }
          }
          webView.navigationDelegate = delegate
        } else {
          fatalError()
        }
      }
    }
  }
}

fileprivate final class ScaledWindow: NSWindow {
  override var backingScaleFactor: CGFloat {
    return 2
  }
}
//#endif
//
private final class NavigationDelegate: NSObject, WKNavigationDelegate {
  var didFinish: () -> Void

  deinit {
    print("!")
  }

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
//#endif
