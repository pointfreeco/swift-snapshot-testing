import Foundation

public struct SyncContinuation<Output>: Sendable {

  fileprivate let block: @Sendable (Result<Output, Error>) -> Void

  fileprivate init(
    block: @Sendable @escaping (Result<Output, Error>) -> Void
  ) {
    self.block = block
  }

  public func resume(with result: Result<Output, Error>) {
    block(result)
  }

  public func resume(returning value: Output) {
    resume(with: .success(value))
  }

  public func resume(throwing error: Error) {
    resume(with: .failure(error))
  }
}

public struct Sync<Input, Output>: SnapshotExecutor {

  private let producer: @Sendable (Input, SyncContinuation<Output>) -> Void

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

  public init(
    _ inputType: Input.Type = Input.self,
    _ block: @escaping @Sendable (Input) throws -> Output
  ) {
    self.init(inputType) { input, continuation in
      continuation.resume(returning: try block(input))
    }
  }

  public func callAsFunction(
    _ input: Input, callback: @escaping @Sendable (Result<Output, Error>) -> Void
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
            })
        case .failure(let error):
          continuation.resume(throwing: error)
        }
      }
    }
  }

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
        })
    }
  }
}

extension Sync where Output: Sendable {

  public func map<NewOutput: Sendable>(
    _ block: @escaping @Sendable (Output) async throws -> NewOutput
  ) -> Async<Input, NewOutput> where Input: Sendable {
    .init { input in
      let output = try await self(input)
      return try await block(output)
    }
  }

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

  public func sleep(nanoseconds duration: UInt64) -> Async<Input, Output> {
    map {
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

@_spi(Internals) public func performOnMainThread<R: Sendable>(_ block: @MainActor () throws -> R)
  rethrows -> R
{
  if Thread.isMainThread {
    try MainActor.assumeIsolated(block)
  } else {
    try DispatchQueue.main.sync(execute: block)
  }
}

private class SyncSequence<Output>: @unchecked Sendable {

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
