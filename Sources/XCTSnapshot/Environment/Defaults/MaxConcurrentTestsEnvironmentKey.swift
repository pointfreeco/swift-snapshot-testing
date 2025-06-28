import Foundation

private struct MaxConcurrentTestsEnvironmentKey: SnapshotEnvironmentKey {

    static var defaultValue: Int {
        TestingSystem.shared.environment?.maxConcurrentTests ?? 3
    }
}

extension SnapshotEnvironmentValues {

    /// The `maxConcurrentTests` property defines the maximum number of concurrent tests allowed during UI testing.
    ///
    /// This property helps prevent device overload and potential capture errors caused by stress on UIKit, SwiftUI, and AppKit frameworks.
    /// It limits the number of `UIWindow` (iOS, tvOS, visionOS) or `NSWindow` (macOS) instances allocated simultaneously during testing.
    ///
    /// The value can be accessed via `SnapshotEnvironment.current.maxConcurrentTests`.
    ///
    /// Default value is `3`. You can modify this value through:
    /// - `withTestingEnvironment(maxConcurrentTests:operation:)`
    /// - Swift Testing framework attributes
    ///
    /// ```swift
    /// // Increase concurrent tests limit
    /// withTestingEnvironment {
    ///     $0.maxConcurrentTests = 5
    /// } operation: {
    ///     // Your testing code here
    /// }
    /// ```
    ///
    /// - Note: This property is specifically applicable to UI tests and helps maintain testing stability on resource-constrained devices.
    /// - SeeAlso:
    ///     - ``withTestingEnvironment(record:diffTool:maxConcurrentTests:platform:operation:file:line:)``
    public var maxConcurrentTests: Int {
        get { self[MaxConcurrentTestsEnvironmentKey.self] }
        set {
            precondition(newValue >= 1)
            self[MaxConcurrentTestsEnvironmentKey.self] = newValue
        }
    }
}
