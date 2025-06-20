#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
#elseif os(macOS)
@preconcurrency import AppKit
#endif

#if os(iOS) || os(tvOS) || os(macOS) || os(visionOS)
@MainActor
private var kUIViewControllerLock = 0

@MainActor
extension SDKViewController {
  
  private var lock: AsyncLock {
    if let lock = objc_getAssociatedObject(self, &kUIViewControllerLock) as? AsyncLock {
      return lock
    }
    
    let lock = AsyncLock()
    objc_setAssociatedObject(self, &kUIViewControllerLock, lock, .OBJC_ASSOCIATION_RETAIN)
    return lock
  }
  
  fileprivate func withLock<Value: Sendable>(_ body: @Sendable () async throws -> Value) async throws -> Value {
    try await lock.withLock(body)
  }
}

extension Snapshot {

  func withLock<Input: SDKViewController, Output: BytesRepresentable>() -> AsyncSnapshot<Input, Output> where Executor == Async<Input, Output> {
    map { executor in
      Async(Input.self) { view in
        try await view.withLock {
          try await executor(view)
        }
      }
    }
  }
}
#endif
