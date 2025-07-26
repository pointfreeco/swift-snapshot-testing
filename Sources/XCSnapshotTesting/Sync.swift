import Foundation

/// A continuation that allows resuming a synchronous operation with a value or error.
///
/// `SyncContinuation` is used to signal the completion of a synchronous operation,
/// either by returning a value or throwing an error. It provides a way to bridge
/// between synchronous and asynchronous code, particularly in the context of
/// ``Sync`` workflows.
///
/// - Note: This type is designed to be `Sendable`, making it suitable for use
///   in concurrent environments.
public struct SyncContinuation<Output>: Sendable {

    fileprivate let block: @Sendable (Result<Output, Error>) -> Void

    fileprivate init(
        block: @Sendable @escaping (Result<Output, Error>) -> Void
    ) {
        self.block = block
    }

    /// Resumes the continuation with a result.
    ///
    /// - Parameter result: The result to resume the continuation with.
    public func resume(with result: Result<Output, Error>) {
        block(result)
    }

    /// Resumes the continuation with a success value.
    ///
    /// - Parameter value: The value to resume the continuation with.
    public func resume(returning value: Output) {
        resume(with: .success(value))
    }

    /// Resumes the continuation by throwing an error.
    ///
    /// - Parameter error: The error to resume the continuation with.
    public func resume(throwing error: Error) {
        resume(with: .failure(error))
    }
}

/// A wrapper for synchronous operations that allows composing and transforming workflows with input and output values.
///
/// `Sync` provides a functional interface for executing synchronous tasks, with support for mapping outputs, pulling back inputs, and inserting delays.
///
/// - Parameters:
///   - Input: The type of input value the synchronous operation accepts.
///   - Output: The type of output value the synchronous operation produces.
public struct Sync<Input, Output>: SnapshotExecutor {

    private let producer: @Sendable (Input, SyncContinuation<Output>) -> Void

    /// Initializes a `Sync` instance with a specific input type and block.
    ///
    /// - Parameters:
    ///   - inputType: The type of input value. This is inferred from the block if not explicitly provided.
    ///   - block: A closure that takes an input value and a continuation for the output, potentially throwing an error.
    public init(
        _ inputType: Input.Type = Input.self,
        _ block: @escaping @Sendable (Input, SyncContinuation<Output>) throws -> Void
    ) {
        self.producer = { input, continuation in
            do {
                try block(input, continuation)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Initializes a `Sync` instance with a specific input type and block.
    ///
    /// - Parameters:
    ///   - inputType: The type of input value. This is inferred from the block if not explicitly provided.
    ///   - block: A closure that takes an input value and returns an output value, potentially throwing an error.
    public init(
        _ inputType: Input.Type = Input.self,
        _ block: @escaping @Sendable (Input) throws -> Output
    ) {
        self.init(inputType) { input, continuation in
            continuation.resume(returning: try block(input))
        }
    }

    /// Invokes the synchronous operation with the given input and completion handler.
    ///
    /// This method allows executing the `Sync` operation by providing an `Input` value and a
    /// completion callback that receives the result. The callback is invoked when the operation
    /// completes, either with a success value or an error.
    ///
    /// - Parameters:
    ///   - input: The input value to pass to the synchronous operation.
    ///   - callback: A closure that handles the result of the operation. It receives a
    ///     `Result<Output, Error>` indicating success or failure.
    ///
    /// - Note: This method is designed for synchronous execution, but the ``SyncContinuation``
    ///   mechanism allows bridging to asynchronous patterns when needed.
    public func callAsFunction(
        _ input: Input,
        callback: @escaping @Sendable (Result<Output, Error>) -> Void
    ) {
        producer(
            input,
            SyncContinuation(block: callback)
        )
    }

    func callAsFunction(_ input: Input) async throws -> Output where Output: Sendable {
        try await withUnsafeThrowingContinuation { continuation in
            self(input) {
                continuation.resume(with: $0)
            }
        }
    }
}

extension Sync {

    /// Transforms the output of this `Sync` operation using a closure that takes the output and a continuation for the new type.
    ///
    /// This method allows for custom transformation logic where the closure can manually manage the continuation
    /// for the new output type. The closure is provided with the original output and a continuation for the new type.
    ///
    /// - Parameters:
    ///   - block: A closure that takes the output of this `Sync` and a continuation for the new output type,
    ///     and performs the transformation.
    ///
    /// - Returns: A new `Sync` instance that produces the transformed output.
    public func map<NewOutput>(
        _ block: @escaping @Sendable (Output, SyncContinuation<NewOutput>) -> Void
    ) -> Sync<Input, NewOutput> {
        .init { input, continuation in
            self(input) { result in
                switch result {
                case .success(let output):
                    block(output, continuation)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Transforms the output of this `Sync` operation using a closure that maps the output to a new type.
    ///
    /// This method provides a convenient way to transform the output by applying a closure that may throw.
    /// The closure is called with the output of this `Sync`, and the result is passed to the continuation.
    ///
    /// - Parameters:
    ///   - block: A closure that takes the output of this `Sync`, may throw an error, and returns a new output type.
    ///
    /// - Returns: A new `Sync` instance that produces the transformed output.
    public func map<NewOutput>(
        _ block: @escaping @Sendable (Output) throws -> NewOutput
    ) -> Sync<Input, NewOutput> {
        .init { input, continuation in
            self(input) { result in
                switch result {
                case .success(let output):
                    continuation.resume(
                        with: Result {
                            try block(output)
                        }
                    )
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Creates a new `Sync` instance that transforms the input using the provided closure.
    ///
    /// This method allows adapting a `NewInput` to the expected `Input` type of the original `Sync` operation.
    /// The closure is responsible for converting the new input into the original input type.
    ///
    /// - Parameter block: A closure that takes a `NewInput` and produces an `Input`, possibly throwing an error.
    /// - Returns: A new `Sync` instance that operates on `NewInput` but uses the original `Input` type internally.
    public func pullback<NewInput>(
        _ block: @escaping @Sendable (NewInput) throws -> Input
    ) -> Sync<NewInput, Output> {
        .init { newInput, continuation in
            do {
                try self(block(newInput)) {
                    continuation.resume(with: $0)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Creates a new `Sync` instance that transforms the input using a continuation-based closure.
    ///
    /// This method provides low-level control over input transformation, allowing asynchronous or
    /// complex logic through the `SyncContinuation` parameter. The closure must handle both success
    /// and failure cases when converting `NewInput` to `Input`.
    ///
    /// - Parameter block: A closure that takes a `NewInput` and a continuation for `Input`, performing
    ///   the transformation asynchronously or with custom logic.
    /// - Returns: A new `Sync` instance that operates on `NewInput` but uses the original `Input` type internally.
    public func pullback<NewInput>(
        _ block: @escaping @Sendable (NewInput, SyncContinuation<Input>) -> Void
    ) -> Sync<NewInput, Output> {
        .init { newInput, continuation in
            block(
                newInput,
                .init {
                    switch $0 {
                    case .success(let input):
                        self(input) {
                            continuation.resume(with: $0)
                        }
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            )
        }
    }
}

extension Sync where Output: Sendable {

    /// Transforms the output of this `Sync` operation using an asynchronous closure that may throw.
    ///
    /// This method allows for asynchronous transformation of the output by applying a closure
    /// that can throw errors. The closure is called with the output of this `Sync`, and the result
    /// is passed to the continuation of the new `Async` instance.
    ///
    /// - Parameters:
    ///   - block: A closure that takes the output of this `Sync`, may throw an error, and returns
    ///     a new output type `NewOutput` which must be `Sendable`.
    ///
    /// - Returns: A new `Async` instance that produces the transformed output.
    public func map<NewOutput: Sendable>(
        _ block: @escaping @Sendable (Output) async throws -> NewOutput
    ) -> Async<Input, NewOutput> where Input: Sendable {
        .init { input in
            let output = try await self(input)
            return try await block(output)
        }
    }

    /// Creates a new `Async` instance that transforms the input using an asynchronous closure.
    ///
    /// This method adapts a `NewInput` to the expected `Input` type of the original `Sync` operation
    /// by applying the provided async closure. The closure may throw errors and returns an `Input`.
    /// The resulting `Async` instance operates on `NewInput` but uses the original `Input` type internally.
    ///
    /// - Parameter block: A closure that takes a `NewInput` and returns an `Input`, possibly throwing an error.
    /// - Returns: A new `Async` instance that produces the original `Output` type, adapted from `NewInput`.
    /// - Requires: `Output` must conform to `Sendable` for this method to be available.
    public func pullback<NewInput: Sendable>(
        _ block: @escaping @Sendable (NewInput) async throws -> Input
    ) -> Async<NewInput, Output> where Output: Sendable {
        .init { newInput in
            let input = try await block(newInput)
            return try await self(input)
        }
    }
}

extension Sync where Input: Sendable, Output: Sendable {

    /// Introduces a delay in the synchronous operation before resuming.
    ///
    /// This method provides a convenient way to pause the execution of a `Sync` operation
    /// for the specified number of nanoseconds. The operation resumes after the delay,
    /// preserving the original input and output values.
    ///
    /// - Parameter duration: The duration of the delay in nanoseconds.
    /// - Returns: An `Async` instance that represents the delayed operation, preserving
    ///           the original input and output types.
    public func sleep(nanoseconds duration: UInt64) -> Async<Input, Output> {
        map {
            try await Task.sleep(nanoseconds: duration)
            return $0
        }
    }

    /// Delays the execution of the synchronous operation until the specified deadline.
    ///
    /// This method introduces a delay in the operation's execution, pausing it until the given `deadline` is reached.
    /// The delay can be adjusted with a `tolerance` and uses the specified `clock` for timing.
    ///
    /// - Parameters:
    ///   - deadline: The time until which the operation should be delayed.
    ///   - tolerance: The allowable deviation from the deadline. If `nil`, no tolerance is applied.
    ///   - clock: The clock to use for measuring time. Defaults to `.continuous`.
    ///
    /// - Returns: An `Async` instance that represents the delayed operation, preserving the original input and output types.
    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    public func sleep<C>(
        until deadline: C.Instant,
        tolerance: C.Instant.Duration? = nil,
        clock: C = .continuous
    ) -> Async<Input, Output> where C: Clock {
        map {
            try await Task.sleep(
                until: deadline,
                tolerance: tolerance,
                clock: clock
            )
            return $0
        }
    }

    /// Delays the execution of the synchronous operation for the specified duration.
    ///
    /// This method introduces a delay in the operation's execution, pausing it for the given `duration`.
    /// The delay can be adjusted with a `tolerance` and uses the specified `clock` for timing.
    ///
    /// - Parameters:
    ///   - duration: The duration of the delay.
    ///   - tolerance: The allowable deviation from the duration. If `nil`, no tolerance is applied.
    ///   - clock: The clock to use for measuring time. Defaults to `.continuous`.
    ///
    /// - Returns: An `Async` instance that represents the delayed operation, preserving
    ///           the original input and output types.
    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    public func sleep<C>(
        for duration: C.Instant.Duration,
        tolerance: C.Instant.Duration? = nil,
        clock: C = .continuous
    ) -> Async<Input, Output> where C: Clock {
        map {
            try await Task.sleep(
                for: duration,
                tolerance: tolerance,
                clock: clock
            )
            return $0
        }
    }
}

@_spi(Internals) public func performOnMainThread<R: Sendable>(
    _ block: @MainActor () throws -> R
) rethrows -> R {
    if Thread.isMainThread {
        try MainActor.assumeIsolated(block)
    } else {
        try DispatchQueue.main.sync(execute: block)
    }
}

private final class SyncSequence<Output>: @unchecked Sendable {

    var items: [Output] {
        lock.withLock { _items }
    }

    private let lock = NSLock()
    private var _items: [Output] = []

    init() {}

    func append(_ item: Output) {
        lock.withLock {
            _items.append(item)
        }
    }
}

extension Array {

    func sequence<Input, Output>() -> Sync<Input, [Output]> where Element == Sync<Input, Output> {
        guard !isEmpty else {
            return Sync { _ in [] }
        }

        return .init { input, continuation in
            let dispatchGroup = DispatchGroup()
            let sequence = SyncSequence<Output>()

            for sync in self {
                dispatchGroup.enter()

                sync(input) { result in
                    if case .success(let output) = result {
                        sequence.append(output)
                    }

                    dispatchGroup.leave()
                }

                dispatchGroup.wait()
            }

            continuation.resume(returning: sequence.items)
        }
    }
}
