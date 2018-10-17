#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
import WebKit
import WKSnapshotConfigurationShim

#if os(macOS)
public typealias Image = NSImage
#elseif os(iOS) || os(tvOS) || os(watchOS)
public typealias Image = UIImage
#endif

@available(iOS 11.0, macOS 10.13, *)
extension SnapshotTestCase {
  public func assertSnapshot(
    matching snapshot: WKWebView,
    named name: String? = nil,
    record recording: Bool = false,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    function: String = #function,
    line: UInt = #line)
  {
    return assertSnapshot(
      matching: snapshot,
      with: .webView,
      named: name,
      record: recording,
      timeout: timeout,
      file: file,
      function: function,
      line: line
    )
  }
}

@available(iOS 11.0, macOS 10.13, *)
extension Strategy {
  public static var webView: Strategy<WKWebView, Image> {
    return .webView(precision: 1)
  }

  public static func webView(precision: Float) -> Strategy<WKWebView, Image> {
    return Strategy.image(precision: precision).asyncContramap { webView in
      Async { callback in
        if webView.frame.size == .zero {
          webView.frame.size = .init(width: 800, height: 600)
        }

        let delegate = NavigationDelegate()
        let work = {
          #if os(macOS)
          if webView.superview == nil {
            let window = ScaledWindow()
            window.contentView = NSView()
            window.contentView?.addSubview(webView)
            window.makeKey()
          }
          #endif

          webView.takeSnapshot(with: nil) { image, _ in
            _ = delegate
            callback(image!)
          }
        }

        if webView.isLoading {
          delegate.didFinish = work
          webView.navigationDelegate = delegate
        } else {
          work()
        }
      }
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
