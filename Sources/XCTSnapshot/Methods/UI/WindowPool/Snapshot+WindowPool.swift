#if os(macOS)
@preconcurrency import AppKit
#elseif os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#endif

#if os(iOS) || os(tvOS) || os(visionOS) || os(macOS)
extension Snapshot {
    func withWindow<NewInput>(
        sessionRole: UISceneSession.Role,
        application: SDKApplication?,
        operation: @escaping @Sendable (SnapshotWindowConfiguration<NewInput>, Executor) async throws
            -> Async<NewInput, Output>
    ) -> AsyncSnapshot<NewInput, Output> {
        map { executor in
            Async(NewInput.self) { @MainActor newInput in
                let windowPool = application?.windowPool ?? WindowPool.shared

                let window = try await windowPool.acquire(
                    sessionRole: sessionRole,
                    maxConcurrentTests: SnapshotEnvironment.current.maxConcurrentTests
                )

                let configuration = SnapshotWindowConfiguration(
                    window: window,
                    input: newInput
                )

                do {
                    let executor = try await operation(configuration, executor)
                    let output = try await executor(newInput)

                    await windowPool.release(window)
                    return output
                } catch {
                    await windowPool.release(window)
                    throw error
                }
            }
        }
    }
}
#endif
