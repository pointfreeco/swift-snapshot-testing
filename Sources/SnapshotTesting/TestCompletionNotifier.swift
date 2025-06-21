import Testing
import Foundation
@_spi(Internals) import XCTSnapshot

public struct FinalizeSnapshotsSuiteTrait: SuiteTrait {
  
  public let isRecursive = false

  #if compiler(>=6.1)
  public func scopeProvider(
    for test: Test,
    testCase: Test.Case?
  ) -> TestScopeProvider? {
    TestScopeProvider()
  }
  #endif
}

extension Trait where Self == FinalizeSnapshotsSuiteTrait {

  public static var finalizeSnapshots: Self {
    .init()
  }
}

#if compiler(>=6.1)
extension FinalizeSnapshotsSuiteTrait {

  public struct TestScopeProvider: TestScoping {
    
    public func provideScope(
      for test: Test,
      testCase: Test.Case?,
      performing function: @Sendable () async throws -> Void
    ) async throws {
      try await withTestCompletionTracking(
        for: test,
        operation: function
      )
    }
  }
}
#endif

private func withTestCompletionTracking<R: Sendable>(
  for test: Test,
  operation: () async throws -> R,
  isolation: isolated Actor? = #isolation,
  file: String = #file,
  line: UInt = #line
) async throws -> R {
  precondition(test.isSuite)

  if TestCompletionNotifier.current != nil {
    return try await operation()
  }

  return try await TestCompletionNotifier.$current.withValue(
    TestCompletionNotifier(test.sourceLocation),
    operation: operation,
    isolation: isolation,
    file: file,
    line: line
  )
}

final class TestCompletionNotifier: Sendable {

  @TaskLocal static var current: TestCompletionNotifier?

  private let sourceLocation: SourceLocation

  fileprivate init(_ sourceLocation: SourceLocation) {
    self.sourceLocation = sourceLocation
  }

  deinit {
    NotificationCenter.default.post(
      name: SwiftTestingDidFinishNotification,
      object: nil,
      userInfo: [
        kTestFileName: sourceLocation.fileName
      ]
    )
  }
}
