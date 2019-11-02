import Foundation
import XCTest

extension Snapshotting {
  public static func wait(
    for duration: TimeInterval,
    on strategy: Snapshotting
  ) -> Snapshotting {
    return Snapshotting(
      pathExtension: strategy.pathExtension,
      diffing: strategy.diffing,
      asyncSnapshot: { value in
        Async { callback in
          let expectation = XCTestExpectation(description: "Wait")
          DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            expectation.fulfill()
          }
          _ = XCTWaiter.wait(for: [expectation], timeout: duration + 1)
          strategy.snapshot(value).run(callback)
        }
    })
  }
}
