import Foundation

final class SnapshotTestingLockedState<Value>: @unchecked Sendable {
  // Safety invariant: all access to `value` happens while holding `lock`.
  private var value: Value
  private let lock = NSLock()

  init(_ value: Value) {
    self.value = value
  }

  func withValue<Result>(_ operation: (inout Value) -> Result) -> Result {
    lock.lock()
    defer { lock.unlock() }
    return operation(&value)
  }
}
