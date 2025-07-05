import Foundation

actor AsyncLock {

    private var isLocked = false
    private var pendingOperations = [AsyncOperation]()

    init() {}

    func withLock<Value: Sendable>(_ block: @Sendable () async throws -> Value) async throws -> Value {
        try await lock()
        defer { unlock() }

        return try await block()
    }

    func withLockVoid(_ block: @Sendable () async throws -> Void) async throws {
        try await lock()
        defer { unlock() }

        try await block()
    }

    func lock() async throws {
        guard isLocked else {
            isLocked = true
            return
        }

        let operation = AsyncOperation()

        try await withTaskCancellationHandler { [weak operation] in
            try await withUnsafeThrowingContinuation {
                guard let operation else {
                    return
                }

                operation.schedule($0)
                pendingOperations.insert(operation, at: .zero)
            }
        } onCancel: {
            operation.cancelled()
        }
    }

    func unlock() {
        guard isLocked else {
            return
        }

        let continuation = pendingOperations.popLast()
        isLocked = !pendingOperations.isEmpty

        continuation?.resume()
    }

    deinit {
        for operation in pendingOperations {
            operation.dispose()
        }
    }
}
