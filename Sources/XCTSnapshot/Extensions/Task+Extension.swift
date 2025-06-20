import Foundation

extension Task where Failure == Error {

  public static func timeout(
    _ timeout: TimeInterval,
    execute closure: @Sendable @escaping () async throws -> Success
  ) async throws -> Success {
    try await withUnsafeThrowingContinuation { continuation in
      let regularTask = Task<Void, Error> {
        let result: Result<Success, Error>

        do {
          let success = try await closure()
          result = .success(success)
        } catch {
          result = .failure(error)
        }

        do {
          try Task<Never, Never>.checkCancellation()
        } catch {}

        continuation.resume(with: result)
      }

      let timeoutTask = Task<Void, Never> {
        do {
          try await Task<Never, Never>.sleep(nanoseconds: UInt64(timeout) * 1_000_000_000)
          do {
            try Task<Never, Never>.checkCancellation()
            continuation.resume(throwing: TaskTimeout())
          } catch {}
        } catch {
          do {
            try Task<Never, Never>.checkCancellation()
            continuation.resume(throwing: error)
          } catch {}
        }
      }

      Task<Void, Never> {
        _ = await timeoutTask.value
        timeoutTask.cancel()
      }

      Task<Void, Never> {
        _ = try? await regularTask.value
        timeoutTask.cancel()
      }
    }
  }
}

public struct TaskTimeout: Error {}
