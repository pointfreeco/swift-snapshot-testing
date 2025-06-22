import Foundation

public struct Async<Input: Sendable, Output: Sendable>: SnapshotExecutor {

  fileprivate let block: @Sendable (Input) async throws -> Output

  public init(
    _ inputType: Input.Type = Input.self,
    _ block: @escaping @Sendable (Input) async throws -> Output
  ) {
    self.block = block
  }

  public func callAsFunction(_ input: Input) async throws -> Output {
    try await block(input)
  }
}

extension Async {

  public func map<NewOutput: Sendable>(
    _ block: @escaping @Sendable (Output) async throws -> NewOutput
  ) -> Async<Input, NewOutput> {
    .init { input in
      let output = try await self(input)
      return try await block(output)
    }
  }

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

  public func sleep(nanoseconds duration: UInt64) -> Async<Input, Output> {
    guard duration > .zero else {
      return self
    }

    return map {
      try await Task.sleep(nanoseconds: duration)
      return $0
    }
  }

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
