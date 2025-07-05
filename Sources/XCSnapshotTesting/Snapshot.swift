import Foundation

/// A protocol defining an executor that processes input to produce a serializable output.
///
/// `SnapshotExecutor` serves as the core processing unit for converting input data into
/// a format compatible with snapshot testing. It defines the relationship between
/// input and output types, and is used by ``Snapshot`` configurations to prepare data
/// for comparison and storage.
///
/// - Notes:
///   - The `Output` type must conform to ``BytesRepresentable`` for serialization/deserialization
///   - Implementations should define how `Input` is transformed into `Output`
///   - Used by ``Snapshot`` configurations to execute processing flows
public protocol SnapshotExecutor<Output>: Sendable {
    associatedtype Input
    associatedtype Output
}

/// A type alias for a synchronous snapshot configuration using ``Sync``.
///
/// `SyncSnapshot` is a convenience type that wraps ``Snapshot`` with a synchronous executor
/// (`Sync<Input, Output>`), enabling synchronous processing of input to serializable output.
///
/// - Parameters:
///   - Input: The type of input data to be processed
///   - Output: The type of output data after processing, must conform to ``BytesRepresentable``
///
/// This type is useful when working with synchronous operations where input needs to be
/// transformed into a format suitable for snapshot testing and comparison.
public typealias SyncSnapshot<Input, Output: BytesRepresentable> = Snapshot<Sync<Input, Output>>

/// A type alias for an asynchronous snapshot configuration using ``Async``.
///
/// `AsyncSnapshot` is a convenience type that wraps ``Snapshot`` with an asynchronous executor
/// (`Async<Input, Output>`), enabling asynchronous processing of input to serializable output.
///
/// - Parameters:
///   - Input: The type of input data to be processed, must conform to `Sendable`
///   - Output: The type of output data after processing, must conform to ``BytesRepresentable``
///
/// This type is useful when working with asynchronous operations where input needs to be
/// transformed into a format suitable for snapshot testing and comparison.
public typealias AsyncSnapshot<Input: Sendable, Output: BytesRepresentable> = Snapshot<
    Async<Input, Output>
>

/// A convenience type for synchronous snapshots where input and output types are identical.
///
/// `IdentitySyncSnapshot` is a shorthand for `SyncSnapshot<Output, Output>`, representing a
/// snapshot configuration where the input data type is the same as the output type. This
/// is useful when no transformation is needed between input and output, and the executor
/// simply passes the input through as the output.
///
/// - Parameters:
///   - Output: The type of data being snapshotted, must conform to ``BytesRepresentable``
///
/// This type simplifies configuration when working with data that doesn't require processing
/// before comparison, such as raw values or unmodified objects.
public typealias IdentitySyncSnapshot<Output: BytesRepresentable> = SyncSnapshot<Output.RawValue, Output>

/// A convenience type for asynchronous snapshots where input and output types are identical.
///
/// `IdentityAsyncSnapshot` is a shorthand for `AsyncSnapshot<Output, Output>`, representing a
/// snapshot configuration where the input data type is the same as the output type. This
/// is useful when no transformation is needed between input and output, and the executor
/// simply passes the input through as the output.
///
/// - Parameters:
///   - Output: The type of data being snapshotted, must conform to ``BytesRepresentable``
///
/// This type simplifies configuration when working with asynchronous data that doesn't require processing
/// before comparison, such as raw values or unmodified objects.
public typealias IdentityAsyncSnapshot<Output: BytesRepresentable> = AsyncSnapshot<Output.RawValue, Output>

/// Configuration defining how snapshots are generated, compared, and displayed during tests.
///
/// `Snapshot` defines parameters including:
/// - Processing executor from input to serializable output
/// - Comparison attachment (diff) generator for mismatch cases
/// - File extension for saved snapshots
///
/// - NOTE: The `Output` type must implement ``BytesRepresentable`` for serialization/deserialization
public struct Snapshot<Executor: SnapshotExecutor>: Sendable where Executor.Output: BytesRepresentable {

    public typealias Input = Executor.Input
    public typealias Output = Executor.Output

    /// The file extension used when saving snapshots (e.g., "json" for JSON files, "png" for images).
    /// This determines the format of the snapshot file stored on disk.
    /// Defaults to `nil` if not explicitly set.
    public let pathExtension: String?

    /// The generator for diagnostic messages/attachments when a snapshot mismatch occurs.
    ///
    /// This attachment generator is responsible for creating visual diffs or diagnostic
    /// information when the actual output doesn't match the expected snapshot. It's used
    /// during test failures to provide detailed comparisons between the actual output
    /// and the stored snapshot.
    ///
    /// - Note: The generator's value type must match the `Output` type of the snapshot
    ///         configuration for proper comparison diagnostics.
    public let attachmentGenerator: any DiffAttachmentGenerator<Executor.Output>

    /// The processing flow that converts `Input` to serializable `Output`.
    /// This executor is responsible for transforming the input data into the output format
    /// compatible with snapshot testing and comparison.
    ///
    /// - Note: The executor is used to prepare data before comparison, ensuring
    ///         output matches the expected format for snapshot storage and validation.
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
    ///       executor: Async { input in
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
    ///   let newConfig = config.map { executor in
    ///       executor.pullback { rawInput in
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

extension IdentitySyncSnapshot where Executor.Output: BytesRepresentable, Executor.Input == Executor.Output.RawValue {

    /// Initializes a new configuration with the specified path extension and attachment generator.
    ///
    /// - Parameters:
    ///   - pathExtension: The file extension used when saving snapshots (e.g., `"png"` for images).
    ///   - attachmentGenerator: Generator for diagnostic messages/attachments on snapshot mismatch.
    ///
    /// Notes:
    ///   - The executor is set to identity function for input type matching.
    ///   - `Output` must match `AttachmentGenerator.Value` type.
    ///
    /// Example:
    ///   ```swift
    ///   let config = IdentitySyncSnapshot(
    ///       pathExtension: "json",
    ///       attachmentGenerator: MyDiffGenerator()
    ///   )
    ///   ```
    public init<Output: BytesRepresentable, AttachmentGenerator>(
        pathExtension: String?,
        attachmentGenerator: AttachmentGenerator
    ) where AttachmentGenerator: DiffAttachmentGenerator<Output>, Executor == Sync<Output.RawValue, Output> {
        self.init(
            pathExtension: pathExtension,
            attachmentGenerator: attachmentGenerator,
            executor: .init { .init(rawValue: $0) }
        )
    }
}

extension IdentityAsyncSnapshot where Executor.Output: BytesRepresentable, Executor.Input == Executor.Output.RawValue {

    /// Initializes a new configuration with the specified path extension and attachment generator for asynchronous context.
    ///
    /// - Parameters:
    ///   - pathExtension: The file extension used when saving snapshots (e.g., `"png"` for images).
    ///   - attachmentGenerator: Generator for diagnostic messages/attachments on snapshot mismatch.
    ///
    /// Notes:
    ///   - The executor is set to identity function for input type matching.
    ///   - `Output` must match `AttachmentGenerator.Value` type.
    ///
    /// Example:
    ///   ```swift
    ///   let config = IdentityAsyncSnapshot(
    ///       pathExtension: "json",
    ///       attachmentGenerator: MyDiffGenerator()
    ///   )
    ///   ```
    public init<Output: BytesRepresentable, AttachmentGenerator>(
        pathExtension: String?,
        attachmentGenerator: AttachmentGenerator
    ) where AttachmentGenerator: DiffAttachmentGenerator<Output>, Executor == Async<Output.RawValue, Output> {
        self.init(
            pathExtension: pathExtension,
            attachmentGenerator: attachmentGenerator,
            executor: .init { .init(rawValue: $0) }
        )
    }
}

extension AsyncSnapshot {

    /// Changes the configuration's input type by applying a closure that transforms new input into the original input type.
    ///
    /// This method allows adapting a snapshot configuration to work with a different input type while reusing the same executor.
    /// The closure is responsible for converting the new input type into the original input type expected by the executor.
    ///
    /// - Parameter closure: A function that takes a new input type and returns the original input type, compatible with the executor.
    /// - Returns: A new snapshot configuration with the updated input type, maintaining the same output type.
    ///
    /// - Note: This is useful for wrapping raw input types with additional processing before passing them to the executor.
    ///
    /// Example:
    /// ```swift
    /// let adaptedConfig = config.pullback { rawInput in
    ///     try await processRawInput(rawInput)
    /// }
    /// ```
    public func pullback<NewInput: Sendable, Input: Sendable, Output: BytesRepresentable>(
        _ closure: @escaping @Sendable (NewInput) async throws -> Input
    ) -> AsyncSnapshot<NewInput, Output> where Executor == Async<Input, Output> {
        map { executor in
            executor.pullback(closure)
        }
    }
}

extension SyncSnapshot {

    /// Changes the configuration's input type by applying a closure that transforms new input into the original input type.
    ///
    /// This method allows adapting a snapshot configuration to work with a different input type while reusing the same executor.
    /// The closure is responsible for converting the new input type into the original input type expected by the executor.
    ///
    /// - Parameter closure: A function that takes a new input type and returns the original input type, compatible with the executor.
    /// - Returns: A new snapshot configuration with the updated input type, maintaining the same output type.
    ///
    /// - Note: This is useful for wrapping raw input types with additional processing before passing them to the executor.
    ///
    /// Example:
    /// ```swift
    /// let adaptedConfig = config.pullback { rawInput in
    ///     try processRawInput(rawInput)
    /// }
    /// ```
    public func pullback<NewInput, Input, Output: BytesRepresentable>(
        _ closure: @escaping @Sendable (NewInput) throws -> Input
    ) -> SyncSnapshot<NewInput, Output> where Executor == Sync<Input, Output> {
        map { executor in
            executor.pullback(closure)
        }
    }

    /// Changes the configuration's input type by applying a closure that transforms new input into the original input type.
    ///
    /// This method allows adapting a snapshot configuration to work with a different input type while reusing the same executor.
    /// The closure is responsible for converting the new input type into the original input type expected by the executor.
    ///
    /// - Parameter closure: A function that takes a new input type and returns the original input type, compatible with the executor.
    /// - Returns: A new snapshot configuration with the updated input type, maintaining the same output type.
    ///
    /// - Note: This is useful for wrapping raw input types with additional processing before passing them to the executor.
    ///
    /// Example:
    /// ```swift
    /// let adaptedConfig = config.pullback { rawInput in
    ///     try await processRawInput(rawInput)
    /// }
    /// ```
    public func pullback<NewInput, Input, Output: BytesRepresentable>(
        _ closure: @escaping @Sendable (NewInput) async throws -> Input
    ) -> AsyncSnapshot<NewInput, Output> where Executor == Sync<Input, Output> {
        map { executor in
            executor.pullback(closure)
        }
    }
}
