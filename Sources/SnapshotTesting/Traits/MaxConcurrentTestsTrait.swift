import Foundation
import Testing
@_spi(Internals) import XCSnapshotTesting

public struct MaxConcurrentTestsTrait: SuiteTrait, TestTrait {
    public let isRecursive = true
    let maxConcurrentTests: Int
}

extension Trait where Self == MaxConcurrentTestsTrait {

    /// Limits the maximum number of tests that can execute concurrently within a suite or for an individual test.
    ///
    /// Use this trait to control the level of parallelism during test execution, which is helpful for tests that are not thread-safe
    /// or when you want to limit resource consumption. When applied to a suite, the limit is enforced recursively for all contained tests and nested suites.
    ///
    /// - Parameter maxConcurrentTests: The maximum number of tests allowed to execute simultaneously. Must be greater than zero.
    /// - Returns: A trait that constrains the test or suite's concurrency.
    ///
    /// Example:
    /// ```swift
    /// @Suite(.maxConcurrentTests(2))
    /// struct MySuite { ... }
    /// ```
    public static func maxConcurrentTests(_ maxConcurrentTests: Int) -> Self {
        .init(maxConcurrentTests: maxConcurrentTests)
    }
}
