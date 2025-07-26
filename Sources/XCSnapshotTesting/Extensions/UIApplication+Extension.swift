#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
#elseif os(macOS)
@preconcurrency import AppKit
#endif

#if os(iOS) || os(tvOS) || os(macOS) || os(visionOS)
@MainActor
extension SDKApplication {

    static var sharedIfAvailable: SDKApplication? {
        let sharedSelector = NSSelectorFromString("sharedApplication")
        guard SDKApplication.responds(to: sharedSelector) else {
            return nil
        }

        let shared = SDKApplication.perform(sharedSelector)
        return shared?.takeUnretainedValue() as! SDKApplication?
    }

    #if os(iOS) || os(tvOS) || os(visionOS)
    func windowScenes(for role: UISceneSession.Role) -> [UIWindowScene] {
        connectedScenes.lazy
            .filter { $0.session.role == role }
            .compactMap { $0 as? UIWindowScene }
    }
    #endif
}

#if os(iOS) || os(tvOS) || os(visionOS)
extension [UIWindowScene] {

    @MainActor
    var keyWindows: [SDKWindow] {
        self.lazy
            .filter { $0.session.role == .windowApplication }
            .reduce([]) {
                $0 + $1.windows.filter(\.isKeyWindow)
            }
    }
}
#endif

@MainActor
private var kUIApplicationLock = 0

@MainActor
extension SDKApplication {

    private var lock: AsyncLock {
        if let lock = objc_getAssociatedObject(self, &kUIApplicationLock) as? AsyncLock {
            return lock
        }

        let lock = AsyncLock()
        objc_setAssociatedObject(self, &kUIApplicationLock, lock, .OBJC_ASSOCIATION_RETAIN)
        return lock
    }

    fileprivate func withLock<Value: Sendable>(
        _ body: @Sendable () async throws -> Value
    ) async throws -> Value {
        try await lock.withLock(body)
    }
}

extension AsyncSnapshot {

    func withLock<Input: SDKApplication, Output: BytesRepresentable>() -> AsyncSnapshot<
        Input, Output
    > where Executor == Async<Input, Output> {
        map { executor in
            Async(Input.self) { application in
                try await application.withLock {
                    try await executor(application)
                }
            }
        }
    }
}
#endif
