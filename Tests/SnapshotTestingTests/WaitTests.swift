import XCTest

@testable import SnapshotTesting

class WaitTests: XCTestCase {
  class UnsafeDelay: @unchecked Sendable {
    var value = "Hello"
  }
  func testWait() async {
    let delay = UnsafeDelay()
    Task {
      delay.value = "Goodbye"
    }

    let strategy = Snapshotting.lines.pullback { (_: Void) in
      delay.value
    }

    await assertSnapshot(matching: (), as: .wait(for: 1.5, on: strategy))
  }
}
