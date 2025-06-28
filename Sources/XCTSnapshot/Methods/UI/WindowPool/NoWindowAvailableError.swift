#if os(macOS)
@preconcurrency import AppKit
#elseif os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#endif

#if os(iOS) || os(tvOS) || os(visionOS) || os(macOS)
struct NoWindowAvailableError: Error, CustomDebugStringConvertible {
    #if !os(macOS)
    let sessionRole: UISceneSession.Role
    #endif

    var debugDescription: String {
        #if !os(macOS)
        """
        Failed to find a valid window for role: \(sessionRole).

        This typically occurs in two scenarios:

        - When running tests in a Package.swift environment, SnapshotTesting cannot \
        instantiate a UIWindowScene because UIApplication may be nil. Verify that the \
        UISceneSession.Role matches the platform's expected behavior (e.g., \
        .windowApplication for iOS apps).

        - When using an xcodeproj, ensure you activate the scene session before testing via: \
        `UIApplication.shared.activateSceneSession(for:)`
        """
        #else
        """
        [BETA OUTPUT]

        Failed to find a valid NSWindow instance for snapshot testing.

        Common causes:

        - NSApplication may not be properly initialized. Ensure sharedApplication is set up \
        before testing begins.

        - The window might not be ordered or key. Verify your window creation flow and call \
        `makeKeyAndOrderFront(_:)` explicitly if needed.
        """
        #endif
    }
}
#endif

#if os(macOS)
enum UISceneSession {
    enum Role {
        case windowApplication
    }
}
#endif
