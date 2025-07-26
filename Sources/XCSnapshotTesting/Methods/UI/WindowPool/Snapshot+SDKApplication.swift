#if os(macOS)
@preconcurrency import AppKit
#elseif os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#endif

#if os(iOS) || os(tvOS) || os(visionOS) || os(macOS)
extension Snapshot {

    func withApplication<NewInput: SDKApplication>(
        sessionRole: UISceneSession.Role,
        operation: @escaping @Sendable (SDKWindow, Executor) async throws -> Async<NewInput, Output>
    ) -> Snapshot<Async<NewInput, Output>> {
        map { executor in
            Async<NewInput, Output> { @MainActor newInput in
                #if os(macOS)
                guard let window = newInput.keyWindow else {
                    throw NoWindowAvailableError()
                }
                #else
                let windowScenes = newInput.windowScenes(for: sessionRole)
                let window = windowScenes.lazy
                    .map(\.windows)
                    .reduce([], +)
                    .first(where: \.isKeyWindow)

                guard let window else {
                    throw NoWindowAvailableError(sessionRole: sessionRole)
                }
                #endif

                let executor = try await operation(window, executor)
                return try await executor(newInput)
            }
        }
    }
}
#endif
