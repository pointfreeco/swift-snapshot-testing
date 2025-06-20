#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
#elseif os(macOS)
@preconcurrency import AppKit
#endif

#if os(iOS) || os(tvOS) || os(macOS) || os(visionOS)
@MainActor
extension SDKWindow {

  @discardableResult
  func removeRootViewController() -> SDKViewController? {
    #if os(macOS)
    if let contentViewController {
      for presentedViewController in contentViewController.presentedViewControllers ?? [] {
        contentViewController.dismiss(presentedViewController)
      }

      contentViewController.view.removeFromSuperview()
      self.contentViewController = nil
      return contentViewController
    }
    #else
    if let rootViewController {
      // Allow the view controller to be deallocated
      rootViewController.dismiss(animated: false) {
        // Remove the root view in case its still showing
        rootViewController.view.removeFromSuperview()
      }

      self.rootViewController = nil

      for subview in subviews {
        subview.removeFromSuperview()
      }

      return rootViewController
    }
    #endif
    return nil
  }

  @discardableResult
  func switchRoot(
    _ viewController: SDKViewController
  ) -> SDKViewController? {
    #if os(macOS)
    let previousRootViewController = removeRootViewController()
    contentViewController = viewController
    #else
    let previousRootViewController = removeRootViewController()
    rootViewController = viewController

    #if !os(tvOS) && !os(visionOS)
    viewController.setNeedsStatusBarAppearanceUpdate()
    #endif
    setNeedsLayout()
    layoutIfNeeded()
    safeAreaInsetsDidChange()
    #endif
    return previousRootViewController
  }
}

@MainActor
extension SDKWindow {

  @MainActor
  private class _Internal: SDKWindow {

    #if os(macOS)
    init(size: CGSize) {
      super.init(
        contentRect: .init(
          origin: .zero,
          size: CGSize(
            width: size.width != .zero ? size.width : CGFloat(NSScreen.main?.frame.width ?? .zero),
            height: size.height != .zero ? size.height : CGFloat(NSScreen.main?.frame.height ?? .zero)
          )
        ),
        styleMask: .resizable,
        backing: .buffered,
        defer: false
      )
    }
    #else
    init(windowScene: UIWindowScene?, size: CGSize) {
      defer { isHidden = false }

      guard let windowScene else {
        super.init(frame: .init(origin: .zero, size: size))
        return
      }

      super.init(windowScene: windowScene)

      frame = .init(origin: .zero, size: CGSize(
        width: size.width == .zero ? frame.width : size.width,
        height: size.height == .zero ? frame.height : size.height
      ))
    }
    #endif

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
  }

  static func make(
    drawHierarchyInKeyWindow: Bool,
    size: CGSize,
    application: SDKApplication? = nil
  ) -> SDKWindow {
    let application = application ?? SDKApplication.sharedIfAvailable

    #if os(macOS)
    if drawHierarchyInKeyWindow, let keyWindow = application?.mainWindow {
      return keyWindow
    } else {
      return _Internal(size: size)
    }
    #else
    let windowScenes = application?.windowScenes

    if drawHierarchyInKeyWindow, let keyWindow = windowScenes?.keyWindows.last(where: { !$0.isHidden }) {
      return keyWindow
    } else {
      return _Internal(
        windowScene: windowScenes?.last,
        size: size
      )
    }
    #endif
  }
}
#endif
