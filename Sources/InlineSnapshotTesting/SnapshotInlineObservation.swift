import Foundation
@_spi(Internals) import XCSnapshotTesting

final class SnapshotInlineObservation: @unchecked Sendable {

    static let shared = SnapshotInlineObservation()

    private let lock = NSLock()

    private var _isObserving = false
    private var _xcObserver: NSObjectProtocol?
    private var _swiftTestingObserver: NSObjectProtocol?

    func registerIfNeeded() {
        lock.withLock {
            guard !_isObserving else {
                return
            }

            _isObserving = true

            _xcObserver = NotificationCenter.default.addObserver(
                forName: XCTestBundleDidFinishNotification,
                object: nil,
                queue: .current,
                using: { [weak self] in self?.xcTestDidFinish($0) }
            )

            _swiftTestingObserver = NotificationCenter.default.addObserver(
                forName: SwiftTestingDidFinishNotification,
                object: nil,
                queue: .current,
                using: { [weak self] in self?.swiftTestDidFinish($0) }
            )
        }
    }

    private func xcTestDidFinish(_ notification: Notification) {
        InlineSnapshotManager.current.writeInlineSnapshots()
    }

    private func swiftTestDidFinish(_ notification: Notification) {
        guard let testName = notification.userInfo?[kTestFileName] as? String else {
            return
        }

        InlineSnapshotManager.current.writeInlineSnapshots(for: testName)
    }
}
