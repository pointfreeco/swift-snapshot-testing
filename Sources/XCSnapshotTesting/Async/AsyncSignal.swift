import Foundation

actor AsyncSignal {

    private var isLocked: Bool
    private var pendingOperations = [AsyncOperation]()

    init(_ locked: Bool = true) {
        isLocked = locked
    }

    func lock() {
        isLocked = true
    }

    func wait() async throws {
        guard isLocked else {
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

    func signal() {
        isLocked = false

        while let operation = pendingOperations.popLast() {
            operation.resume()
        }
    }

    deinit {
        for operation in pendingOperations {
            operation.dispose()
        }
    }
}
