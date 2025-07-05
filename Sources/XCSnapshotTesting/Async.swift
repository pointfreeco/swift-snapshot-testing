import Foundation

/// A wrapper for asynchronous operations that allows composing and transforming asynchronous workflows with input and output values.
///
/// `Async` provides a functional interface for executing asynchronous tasks, with support for mapping outputs, pulling back inputs, and inserting delays.
///
/// - Parameters:
///   - Input: The type of input value the async operation accepts.
///   - Output: The type of output value the async operation produces.
public struct Async<Input: Sendable, Output: Sendable>: SnapshotExecutor {

    fileprivate let block: @Sendable (Input) async throws -> Output

    /// Initializes an `Async` instance with a specific input type and block.
    ///
    /// - Parameters:
    ///   - inputType: The type of input value. This is inferred from the block if not explicitly provided.
    ///   - block: An asynchronous closure that takes an input value and returns an output value, potentially throwing an error.
    public init(
        _ inputType: Input.Type = Input.self,
        _ block: @escaping @Sendable (Input) async throws -> Output
    ) {
        self.block = block
    }

    /// Executes the asynchronous operation with the provided input value.
    ///
    /// - Parameter input: The input value to pass to the asynchronous operation.
    /// - Returns: The output value produced by the operation.
    /// - Throws: Any error thrown by the asynchronous operation.
    public func callAsFunction(_ input: Input) async throws -> Output {
        try await block(input)
    }
}

extension Async {

    /// Transforms the output of the asynchronous operation using a new closure.
    ///
    /// - Parameter block: A closure that takes the original output and returns a new value of type `NewOutput`.
    /// - Returns: A new `Async` instance that applies this transformation.
    public func map<NewOutput: Sendable>(
        _ block: @escaping @Sendable (Output) async throws -> NewOutput
    ) -> Async<Input, NewOutput> {
        .init { input in
            let output = try await self(input)
            return try await block(output)
        }
    }

    /// Transforms the input of the asynchronous operation using a new closure.
    ///
    /// - Parameter block: A closure that takes a new input value and returns a value of type `Input` to pass to this operation.
    /// - Returns: A new `Async` instance that applies this input transformation.
    public func pullback<NewInput: Sendable>(
        _ block: @escaping @Sendable (NewInput) async throws -> Input
    ) -> Async<NewInput, Output> {
        .init { newInput in
            let input = try await block(newInput)
            return try await self(input)
        }
    }
}

extension Async {

    /// Adds a delay before completing the asynchronous operation.
    ///
    /// - Parameter duration: The duration of the delay in nanoseconds.
    /// - Returns: A new `Async` instance with the delay applied.
    public func sleep(nanoseconds duration: UInt64) -> Async<Input, Output> {
        guard duration > .zero else {
            return self
        }

        return map {
            try await Task.sleep(nanoseconds: duration)
            return $0
        }
    }

    /// Adds a delay until a specific deadline before completing the asynchronous operation.
    ///
    /// - Parameters:
    ///   - deadline: The instant at which the delay should end.
    ///   - tolerance: The allowed tolerance for the deadline.
    ///   - clock: The clock to use for measuring time.
    /// - Returns: A new `Async` instance with the delay applied.
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

    /// Adds a delay for a specific duration before completing the asynchronous operation.
    ///
    /// - Parameters:
    ///   - duration: The duration of the delay.
    ///   - tolerance: The allowed tolerance for the duration.
    ///   - clock: The clock to use for measuring time.
    /// - Returns: A new `Async` instance with the delay applied.
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
