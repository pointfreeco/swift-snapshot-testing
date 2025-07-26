import Foundation

extension Task where Failure == Error {

    public static func timeout(
        _ timeout: TimeInterval,
        execute closure: @Sendable @escaping () async throws -> Success
    ) async throws -> Success {
        try await withUnsafeThrowingContinuation { continuation in
            let regularTask = Task<Void, Never> {
                let result: Result<Success, Error>

                do {
                    result = .success(try await closure())
                } catch {
                    result = .failure(error)
                }

                do {
                    try Task<Never, Never>.checkCancellation()
                } catch {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(with: result)
            }

            let timeoutTask = Task<Void, Error> {
                try await Task<Never, Never>.sleep(
                    nanoseconds: UInt64(timeout) * 1_000_000_000
                )
                continuation.resume(throwing: TaskTimeout())
            }

            Task<Void, Never> {
                _ = try? await timeoutTask.value
                timeoutTask.cancel()
            }

            Task<Void, Never> {
                _ = await regularTask.value
                timeoutTask.cancel()
            }
        }
    }
}

public struct TaskTimeout: Error {}
