import Foundation
import Testing
@_spi(Internals) import XCSnapshotTesting

public struct FinalizeSnapshotsSuiteTrait: SuiteTrait {

    public let isRecursive = false

    public func scopeProvider(
        for test: Test,
        testCase: Test.Case?
    ) -> TestScopeProvider? {
        TestScopeProvider()
    }
}

extension Trait where Self == FinalizeSnapshotsSuiteTrait {

    /// A suite trait that finalizes all snapshot tests after the suite completes execution.
    ///
    /// Use this trait to automatically trigger snapshot finalization logic—
    /// such as emitting notifications or performing cleanup—after all tests
    /// in a suite have finished running. This is useful for ensuring that any
    /// resources or state associated with snapshot testing are properly handled
    /// after tests conclude.
    ///
    /// Apply this trait to your test suite using the `@Suite(.finalizeSnapshots)`
    /// macro.
    ///
    /// Example:
    /// ```swift
    /// @Suite(.finalizeSnapshots)
    /// struct MySnapshotTests { ... }
    /// ```
    ///
    /// - Note: This trait is non-recursive and will only apply to the suite where it is specified.
    public static var finalizeSnapshots: Self {
        .init()
    }
}

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
