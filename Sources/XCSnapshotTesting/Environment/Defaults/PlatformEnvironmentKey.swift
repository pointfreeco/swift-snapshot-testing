import Foundation

#if os(iOS)
import UIKit
#endif

private struct PlatformEnvironmentKey: SnapshotEnvironmentKey {

    static var defaultValue: String {
        TestingSystem.shared.environment?.platform ?? operatingSystemName()
    }

    private static func operatingSystemName() -> String {
        #if os(macOS)
        return "macOS"
        #elseif os(iOS)
        #if targetEnvironment(macCatalyst)
        return "macCatalyst"
        #else
        return performOnMainThread {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return "iPadOS"
            } else {
                return "iOS"
            }
        }
        #endif
        #elseif os(tvOS)
        return "tvOS"
        #elseif os(watchOS)
        return "watchOS"
        #elseif os(visionOS)
        return "visionOS"
        #elseif os(Android)
        return "android"
        #elseif os(Windows)
        return "windows"
        #elseif os(Linux)
        return "linux"
        #elseif os(WASI)
        return "wasi"
        #else
        return "unknown"
        #endif
    }
}

extension SnapshotEnvironmentValues {

    /// The platform name used in snapshot URLs to distinguish test outputs.
    ///
    /// This property helps differentiate snapshots across platforms with different UI frameworks (like UIKit and SwiftUI on iOS vs. AppKit on macOS).
    /// It ensures that platform-specific UI layouts do not interfere with each other during testing.
    ///
    /// The value defaults to the current platform (e.g., "iOS", "macOS") unless explicitly configured through:
    /// - `withTestingEnvironment(platform:operation:)`
    /// - Swift Testing framework traits
    ///
    /// Setting this to an empty string will make snapshots share the same output path without platform-specific distinction.
    ///
    /// Accessed via `SnapshotEnvironment.current.platform`.
    ///
    /// ```swift
    /// // Customize platform name for snapshots
    /// withTestingEnvironment {
    ///     $0.platform = "iOS-Simulator"
    /// } operation: {
    ///     // Your testing code here
    /// }
    /// ```
    ///
    /// - Note: This is particularly useful for UI snapshot testing where different platforms may have different default layouts and behaviors.
    /// - SeeAlso:
    ///     - ``withTestingEnvironment(record:diffTool:maxConcurrentTests:platform:operation:file:line:)``
    public var platform: String {
        get { self[PlatformEnvironmentKey.self] }
        set { self[PlatformEnvironmentKey.self] = newValue }
    }
}
