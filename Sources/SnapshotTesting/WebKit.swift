#if os(iOS) || os(macOS)
#if !COCOAPODS
import WKSnapshotConfigurationShim
#endif

import XCTest

@available(iOS 11.0, macOS 10.13, *)
public func assertSnapshot(
  matching webView: WKWebView,
  named name: String? = nil,
  pathExtension: String? = "png",
  record recording: Bool = SnapshotTesting.record,
  file: StaticString = #file,
  function: String = #function,
  line: UInt = #line)
{
  let fail = { XCTFail($0, file: file, line: line) }
  if webView.frame.size == .zero {
    webView.frame.size = .init(width: 800, height: 600)
  }
  if webView.isLoading {
    let loadedWebPage = XCTestExpectation()
    let delegate = NavigationDelegate(didFinish: loadedWebPage.fulfill)
    webView.navigationDelegate = delegate
    guard XCTWaiter.wait(for: [loadedWebPage], timeout: 5.0) == .completed else {
      fail("Timed out loading web page.")
      return
    }
  }
  let tookSnapshot = XCTestExpectation()
  #if os(macOS)
  if webView.superview == nil {
    let window = ScaledWindow()
    window.contentView = NSView()
    window.contentView?.addSubview(webView)
    window.makeKey()
  }
  #endif
  webView.takeSnapshot(with: nil) { image, error in
    tookSnapshot.fulfill()
    assertSnapshot(
      matching: image ?? .init(),
      named: name,
      pathExtension: pathExtension,
      record: recording,
      file: file,
      function: function,
      line: line
    )
  }
  guard XCTWaiter.wait(for: [tookSnapshot], timeout: 5.0) == .completed else {
    fail("Timed out taking snapshot.")
    return
  }
}

#if os(macOS)
fileprivate final class ScaledWindow: NSWindow {
  override var backingScaleFactor: CGFloat {
    return 2
  }
}
#endif

private final class NavigationDelegate: NSObject, WKNavigationDelegate {
  let didFinish: () -> Void

  init(didFinish: @escaping () -> Void) {
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
