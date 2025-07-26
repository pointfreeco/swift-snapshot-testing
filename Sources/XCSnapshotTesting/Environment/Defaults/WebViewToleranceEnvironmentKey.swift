import Foundation

#if os(iOS) || os(visionOS) || os(macOS) || os(visionOS)
private struct WebViewToleranceEnvironmentKey: SnapshotEnvironmentKey {
    static let defaultValue: TimeInterval = 2.5
}

extension SnapshotEnvironmentValues {

    /// The maximum time (in seconds) to wait for a web view to load before taking a snapshot.
    ///
    /// This property configures the timeout duration for web view loading during snapshot operations.
    /// It helps prevent tests from failing due to network latency or complex web content loading.
    ///
    /// - Default: 2.5 seconds
    /// - Available on: iOS, iPadOS, macOS, visionOS
    ///
    /// ```swift
    /// // Increase web view loading timeout
    /// withTestingEnvironment {
    ///     $0.webViewTolerance = 5.0
    /// } operation: {
    ///     // Your web view testing code here
    /// }
    /// ```
    ///
    /// - Note: This setting is particularly useful when testing views containing `WKWebView` or similar web-rendering components.
    /// - SeeAlso: ``withTestingEnvironment(_:operation:file:line:)``
    public var webViewTolerance: TimeInterval {
        get { self[WebViewToleranceEnvironmentKey.self] }
        set { self[WebViewToleranceEnvironmentKey.self] = newValue }
    }
}
#endif
