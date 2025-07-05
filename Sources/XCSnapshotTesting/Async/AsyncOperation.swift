import Foundation

final class AsyncOperation: @unchecked Sendable {

    private enum State {
        case idle
        case scheduled(UnsafeContinuation<Void, Error>)
        case cancelled
    }

    private let lock = NSLock()
    private var _state: State = .idle

    init() {}

    func schedule(_ continuation: UnsafeContinuation<Void, Error>) {
        lock.withLock {
            if case .idle = _state {
                _state = .scheduled(continuation)
            }
        }
    }

    func resume() {
        lock.withLock {
            if case .scheduled(let continuation) = _state {
                continuation.resume()
            }
        }
    }

    func cancelled() {
        lock.withLock {
            _state = .cancelled
        }
    }

    func dispose() {
        lock.withLock {
            if case .scheduled(let continuation) = _state {
                continuation.resume(throwing: CancellationError())
            }
        }
    }
}
