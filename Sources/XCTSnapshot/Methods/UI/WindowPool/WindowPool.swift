import Foundation

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
#elseif os(macOS)
@preconcurrency import AppKit
#endif

#if os(iOS) || os(tvOS) || os(macOS) || os(visionOS)
@MainActor
final class WindowPool {

    // MARK: - Internal static properties

    static let shared = WindowPool(SDKApplication.sharedIfAvailable)

    // MARK: - Private properties

    private var leases: [WindowLease] = []
    private weak var application: SDKApplication?

    #if !os(macOS)
    private var activeWindowScenes: [UIWindowScene] {
        leases.compactMap(\.window.windowScene)
    }
    #endif

    // MARK: - Inits

    init(_ application: SDKApplication?) {
        self.application = application
    }

    // MARK: - Internal methods

    func acquire(
        sessionRole: UISceneSession.Role,
        maxConcurrentTests: Int
    ) async throws -> SDKWindow {
        #if !os(macOS)
        let windowScene = try windowScene(for: sessionRole)
        #endif

        if leases.count >= maxConcurrentTests {
            let leases = leases[0..<maxConcurrentTests]
            let lease = leases.sorted(by: {
                $0.pendingTasks >= $1.pendingTasks
            }).first!
            try await lease.lock()
            #if !os(macOS)
            lease.window.windowScene = windowScene
            #endif
            display(lease.window, visible: true)
            return lease.window
        }

        #if os(macOS)
        let window = SDKWindow()
        window.isReleasedWhenClosed = false
        #else
        let window = SDKWindow(windowScene: windowScene)
        #endif

        display(window, visible: true)

        let WindowLease = WindowLease(window: window)
        leases.append(WindowLease)
        try await WindowLease.lock()
        return window
    }

    func release(_ window: SDKWindow) async {
        defer { display(window, visible: false) }

        await window.windowLease?.unlock()
    }

    // MARK: - Private methods

    #if !os(macOS)
    private func windowScene(for sessionRole: UISceneSession.Role) throws -> UIWindowScene {
        if let windowScene = application?.windowScenes(for: sessionRole).first {
            return windowScene
        }

        if let windowScene = activeWindowScenes.first(where: { $0.session.role == sessionRole }) {
            return windowScene
        }

        if #available(iOS 17, tvOS 17, *) {
            if let windowScene = activateNewSceneSession(sessionRole) {
                return windowScene
            }
        }

        if let windowScene = windowSceneThroughTemporaryWindow(sessionRole) {
            return windowScene
        }

        throw NoWindowAvailableError(sessionRole: sessionRole)
    }

    @available(iOS 17, tvOS 17, *)
    private func activateNewSceneSession(_ sessionRole: UISceneSession.Role) -> UIWindowScene? {
        guard let application = application else {
            return nil
        }

        application.activateSceneSession(
            for: UISceneSessionActivationRequest(role: sessionRole)
        )

        return application.windowScenes(for: sessionRole).first
    }

    private func windowSceneThroughTemporaryWindow(
        _ sessionRole: UISceneSession.Role
    ) -> UIWindowScene? {
        let window = SDKWindow()
        window.isHidden = false

        defer {
            window.isHidden = true
            window.windowScene = nil
        }

        return window.windowScene
    }
    #endif

    private func display(_ window: SDKWindow, visible: Bool) {
        #if os(macOS)
        if !visible {
            window.close()
        } else {
            window.setIsVisible(visible)
        }
        #else
        window.isHidden = !visible
        #endif

        guard visible else {
            return
        }

        #if os(macOS)
        guard let screen = window.screen else {
            return
        }

        let screenSize = screen.frame.size
        if window.frame.size != screenSize {
            window.setFrame(
                NSRect(origin: .zero, size: screenSize),
                display: true
            )
        }
        #elseif os(iOS) || os(tvOS)
        let screenSize = window.screen.bounds.size

        if window.bounds.size != screenSize {
            window.frame = .init(origin: .zero, size: screenSize)
        }
        #endif
    }
}

// MARK: - SnapshotWindowConfiguration

@MainActor
private var kApplicationWindowPool = 0

@MainActor
extension SDKApplication {

    var windowPool: WindowPool {
        if let windowPool = objc_getAssociatedObject(self, &kApplicationWindowPool) as? WindowPool {
            return windowPool
        }

        let windowPool = WindowPool(self)
        objc_setAssociatedObject(self, &kApplicationWindowPool, windowPool, .OBJC_ASSOCIATION_RETAIN)
        return windowPool
    }
}
#endif
