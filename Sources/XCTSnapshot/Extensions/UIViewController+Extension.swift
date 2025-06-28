#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
#elseif os(macOS)
@preconcurrency import AppKit
#endif

#if os(iOS) || os(tvOS) || os(macOS) || os(visionOS)
@MainActor
private var kUIViewControllerLock = 0

@MainActor
extension SDKViewController {

    private var lock: AsyncLock {
        if let lock = objc_getAssociatedObject(self, &kUIViewControllerLock) as? AsyncLock {
            return lock
        }

        let lock = AsyncLock()
        objc_setAssociatedObject(self, &kUIViewControllerLock, lock, .OBJC_ASSOCIATION_RETAIN)
        return lock
    }

    fileprivate func withLock<Value: Sendable>(
        _ body: @Sendable () async throws -> Value
    ) async throws -> Value {
        try await lock.withLock(body)
    }
}

extension Snapshot {

    func withLock<Input: SDKViewController, Output: BytesRepresentable>() -> AsyncSnapshot<
        Input, Output
    > where Executor == Async<Input, Output> {
        map { executor in
            Async(Input.self) { view in
                try await view.withLock {
                    try await executor(view)
                }
            }
        }
    }
}
#endif

#if os(iOS) || os(tvOS) || os(visionOS)
@MainActor
private var kUIViewControllerTraits = 0

extension SDKViewController {

    private var traits: Traits? {
        get { objc_getAssociatedObject(self, &kUIViewControllerTraits) as? Traits }
        set {
            objc_setAssociatedObject(
                self,
                &kUIViewControllerTraits,
                newValue,
                .OBJC_ASSOCIATION_RETAIN
            )
        }
    }

    func inconsistentTraitsChecker(for traits: Traits) {
        defer { self.traits = traits }
        self.traits?.inconsistentTraitsChecker(self, to: traits)
    }
}

extension Snapshot {

    func inconsistentTraitsChecker<Input: SDKViewController, Output: BytesRepresentable>(
        _ traits: Traits
    ) -> AsyncSnapshot<Input, Output> where Executor == Async<Input, Output> {
        map { executor in
            Async(Input.self) { @MainActor in
                $0.inconsistentTraitsChecker(for: traits)
                return try await executor($0)
            }
        }
    }
}
#endif
