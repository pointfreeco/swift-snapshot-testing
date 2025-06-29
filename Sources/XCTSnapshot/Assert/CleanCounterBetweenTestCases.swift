#if canImport(XCTest)
import XCTest

final class CleanCounterBetweenTestCases: NSObject, XCTestObservation {

    @MainActor
    private static var registered = false

    fileprivate static func registerIfNeeded() {
        performOnMainThread {
            guard !registered else { return }
            registered = true
            XCTestObservationCenter.shared.addTestObserver(CleanCounterBetweenTestCases())
        }
    }

    func testBundleDidFinish(_ testBundle: Bundle) {
        NotificationCenter.default.post(
            name: XCTestBundleDidFinishNotification,
            object: nil
        )
    }
}

extension XCTestCase {

    static func registerObserverIfNeeded() {
        CleanCounterBetweenTestCases.registerIfNeeded()
    }
}
#endif

@_spi(Internals)
public let XCTestBundleDidFinishNotification = Notification.Name(
    "XCTestBundleDidFinishNotification"
)

@_spi(Internals)
public let SwiftTestingDidFinishNotification = Notification.Name(
    "SwiftTestingDidFinishNotification"
)

@_spi(Internals)
public let kTestFileName = "kTestFileName"
