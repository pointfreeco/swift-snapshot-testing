import Foundation

#if os(iOS) || os(visionOS) || os(macOS) || os(visionOS)
  private struct WebViewToleranceEnvironmentKey: SnapshotEnvironmentKey {
    static let defaultValue: TimeInterval = 2.5
  }

  extension SnapshotEnvironmentValues {

    public var webViewTolerance: TimeInterval {
      get { self[WebViewToleranceEnvironmentKey.self] }
      set { self[WebViewToleranceEnvironmentKey.self] = newValue }
    }
  }
#endif
