import Foundation

#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

private struct IncludeMajorPlatformVersionInPathEnvironmentKey: SnapshotEnvironmentKey {
    static let defaultValue = false
}

extension SnapshotEnvironmentValues {

    /// A Boolean value that determines whether the major platform version is included in the path during snapshot testing.
    ///
    /// When `true`, the snapshot paths will include the major version of the platform (e.g., "v14" for iOS 14).
    /// This is useful for ensuring snapshots are version-specific and avoid conflicts between different platform versions.
    ///
    /// - Note: The value is retrieved from the `SnapshotEnvironmentValues`:
    ///   - `SnapshotEnvironment.current.includeMajorPlatformVersionInPath`
    ///   - Or set within a testing environment closure:
    ///
    ///         withTestingEnvironment {
    ///             $0.includeMajorPlatformVersionInPath = true
    ///         } operation: { ... }
    ///
    /// Platform version retrieval is handled differently across platforms:
    /// - **macOS**: Parses the OS version, handling macOS 10.x specially.
    /// - **iOS/tvOS/visionOS**: Uses `UIDevice.current.systemVersion` on the main thread.
    /// - **watchOS**: Uses `WKInterfaceDevice.current().systemVersion` on the main thread.
    ///
    /// The final version string is formatted as "v\{MajorVersion}".
    ///
    /// ```swift
    /// // Enable versioned paths
    /// withTestingEnvironment {
    ///     $0.includeMajorPlatformVersionInPath = true
    /// } operation: {
    ///     // Your testing code here
    /// }
    /// ```
    public var includeMajorPlatformVersionInPath: Bool {
        get { self[IncludeMajorPlatformVersionInPathEnvironmentKey.self] }
        set { self[IncludeMajorPlatformVersionInPathEnvironmentKey.self] = newValue }
    }

    var platformVersion: String? {
        guard includeMajorPlatformVersionInPath, !platform.isEmpty else {
            return nil
        }

        let majorVersion: String?
        #if os(macOS)
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 10 {
            let systemVersion = ProcessInfo.processInfo.operatingSystemVersion
            majorVersion = "\(systemVersion.majorVersion).\(systemVersion.minorVersion)"
        } else {
            majorVersion = String(ProcessInfo.processInfo.operatingSystemVersion.majorVersion)
        }
        #elseif os(iOS) || os(tvOS) || os(visionOS)
        majorVersion = performOnMainThread {
            UIDevice.current.systemVersion.split(separator: ".").first.map(String.init)
        }
        #elseif os(watchOS)
        majorVersion = performOnMainThread {
            WKInterfaceDevice.current().systemVersion.split(separator: ".").first.map(String.init)
        }
        #else
        majorVersion = String(ProcessInfo.processInfo.operatingSystemVersion.majorVersion)
        #endif

        return majorVersion.map { "v\($0)" }
    }
}
