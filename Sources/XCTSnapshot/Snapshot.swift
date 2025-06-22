import Foundation

public protocol SnapshotExecutor<Output>: Sendable {
  associatedtype Input
  associatedtype Output
}

public typealias SyncSnapshot<Input, Output: BytesRepresentable> = Snapshot<Sync<Input, Output>>

public typealias AsyncSnapshot<Input: Sendable, Output: BytesRepresentable> = Snapshot<
  Async<Input, Output>
>

public typealias IdentitySyncSnapshot<Output: BytesRepresentable> = SyncSnapshot<Output, Output>

public typealias IdentityAsyncSnapshot<Output: BytesRepresentable> = AsyncSnapshot<Output, Output>

/// Configuration defining how snapshots are generated, compared, and displayed during tests.
///
/// `Snapshot` defines parameters including:
/// - Processing executor from input to serializable output
/// - Comparison attachment (diff) generator for mismatch cases
/// - File extension for saved snapshots
///
/// - NOTE: The `Output` type must implement `BytesRepresentable` for serialization/deserialization
public struct Snapshot<Executor: SnapshotExecutor>: Sendable
where Executor.Output: BytesRepresentable {

  public typealias Input = Executor.Input
  public typealias Output = Executor.Output

  public let pathExtension: String?
  public let attachmentGenerator: any DiffAttachmentGenerator<Executor.Output>
  public let executor: Executor

  /// Initializes configuration with executor, diff generator, and storage options.
  ///
  /// - Parameters:
  ///   - pathExtension: File extension used when saving snapshots (e.g., `"png"` for images)
  ///   - attachmentGenerator: Generator for diagnostic messages/attachments on snapshot mismatch
  ///   - executor: Processing flow that converts `Input` to serializable `Output`
  ///
  /// Notes:
  ///   - `Output` must match `AttachmentGenerator.Value` type
  ///   - Executor executes before comparison to prepare data
  ///
  /// Example:
  ///   ```swift
  ///   let config = Snapshot(
  ///       pathExtension: "json",
  ///       attachmentGenerator: MyDiffGenerator(),
  ///       executor: Executor.start { input in
  ///           return try await encodeToJSON(input)
  ///       }
  ///   )
  ///   ```
  public init<AttachmentGenerator>(
    pathExtension: String? = nil,
    attachmentGenerator: AttachmentGenerator,
    executor: Executor
  ) where AttachmentGenerator: DiffAttachmentGenerator<Executor.Output> {
    self.pathExtension = pathExtension
    self.attachmentGenerator = attachmentGenerator
    self.executor = executor
  }

  /// Changes the configuration's input type using a executor transformation closure.
  ///
  /// - Parameter closure: Function receiving current executor and returning new executor with modified input type
  /// - Returns: New configuration with updated input type and same output
  ///
  /// Notes:
  ///   - Useful for adapting existing configurations to new input types
  ///   - Propagates errors from closure
  ///
  /// Example:
  ///   ```swift
  ///   let newConfig = config.map { existingPipeline in
  ///       existingPipeline.pullback { rawInput in
  ///           try await processRawInput(rawInput)
  ///       }
  ///   }
  ///   ```
  public func map<NewExecutor: SnapshotExecutor>(
    _ closure: @Sendable (Executor) throws -> NewExecutor
  ) rethrows -> Snapshot<NewExecutor> where NewExecutor.Output == Executor.Output {
    Snapshot<NewExecutor>(
      pathExtension: pathExtension,
      attachmentGenerator: attachmentGenerator,
      executor: try closure(executor)
    )
  }
}

extension IdentitySyncSnapshot where Executor.Input == Executor.Output {

  public init<Output: BytesRepresentable, AttachmentGenerator>(
    pathExtension: String?,
    attachmentGenerator: AttachmentGenerator
  ) where AttachmentGenerator: DiffAttachmentGenerator<Output>, Executor == Sync<Output, Output> {
    self.init(
      pathExtension: pathExtension,
      attachmentGenerator: attachmentGenerator,
      executor: .init { $0 }
    )
  }
}

extension IdentityAsyncSnapshot where Executor.Input == Executor.Output {

  public init<Output: BytesRepresentable, AttachmentGenerator>(
    pathExtension: String?,
    attachmentGenerator: AttachmentGenerator
  ) where AttachmentGenerator: DiffAttachmentGenerator<Output>, Executor == Async<Output, Output> {
    self.init(
      pathExtension: pathExtension,
      attachmentGenerator: attachmentGenerator,
      executor: .init { $0 }
    )
  }
}

extension AsyncSnapshot {

  public func pullback<NewInput: Sendable, Input: Sendable, Output: BytesRepresentable>(
    _ closure: @escaping @Sendable (NewInput) async throws -> Input
  ) -> AsyncSnapshot<NewInput, Output> where Executor == Async<Input, Output> {
    map { executor in
      executor.pullback(closure)
    }
  }
}

extension SyncSnapshot {

  public func pullback<NewInput, Input, Output: BytesRepresentable>(
    _ closure: @escaping @Sendable (NewInput) throws -> Input
  ) -> SyncSnapshot<NewInput, Output> where Executor == Sync<Input, Output> {
    map { executor in
      executor.pullback(closure)
    }
  }

  public func pullback<NewInput, Input, Output: BytesRepresentable>(
    _ closure: @escaping @Sendable (NewInput) async throws -> Input
  ) -> AsyncSnapshot<NewInput, Output> where Executor == Sync<Input, Output> {
    map { executor in
      executor.pullback(closure)
    }
  }
}
