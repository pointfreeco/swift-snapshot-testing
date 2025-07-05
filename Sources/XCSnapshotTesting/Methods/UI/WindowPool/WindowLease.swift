#if os(macOS)
@preconcurrency import AppKit
#elseif os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#endif

#if os(iOS) || os(tvOS) || os(visionOS) || os(macOS)
@MainActor
class WindowLease {

    private let _lock = AsyncLock()
    private(set) var pendingTasks: Int = .zero

    let window: SDKWindow

    init(window: SDKWindow) {
        self.window = window
        window.windowLease = self
    }

    func lock() async throws {
        pendingTasks += 1
        try await _lock.lock()
        pendingTasks -= 1
    }

    func unlock() async {
        await _lock.unlock()
    }
}

@MainActor
private var kWindowLeaseKey = 0

@MainActor
extension SDKWindow {

    fileprivate(set) var windowLease: WindowLease? {
        get {
            objc_getAssociatedObject(self, &kWindowLeaseKey) as? WindowLease
        }
        set {
            precondition(windowLease == nil)

            objc_setAssociatedObject(
                self,
                &kWindowLeaseKey,
                newValue,
                .OBJC_ASSOCIATION_ASSIGN
            )
        }
    }
}
#endif
