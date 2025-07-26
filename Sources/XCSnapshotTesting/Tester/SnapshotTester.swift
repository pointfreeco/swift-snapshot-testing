import Foundation

#if canImport(XCTest)
import XCTest
#endif

@_spi(Internals)
public struct SnapshotTester<Engine: SnapshotEngine>: Sendable {

    public typealias Executor = Engine.Executor

    public let serialization: DataSerialization
    public let timeout: TimeInterval

    public let fileID: StaticString
    public let filePath: StaticString
    public let function: StaticString
    public let line: UInt
    public let column: UInt

    public let platform: String
    public let platformVersion: String?

    private let engine: Engine
    private let record: RecordMode
    private let name: String?

    public init(
        engine: Engine,
        record: RecordMode?,
        timeout: TimeInterval,
        name: String?,
        serialization: DataSerialization,
        fileID: StaticString,
        filePath: StaticString,
        function: StaticString,
        line: UInt,
        column: UInt
    ) {
        if !TestingSystem.shared.isSwiftTestingRunning {
            #if canImport(XCTest)
            XCTestCase.registerObserverIfNeeded()
            #endif
        }

        self.engine = engine
        self.record = record ?? SnapshotEnvironment.current.recordMode
        self.platform = SnapshotEnvironment.current.platform
        self.platformVersion = SnapshotEnvironment.current.platformVersion
        self.timeout = timeout
        self.name = name
        self.serialization = serialization
        self.fileID = fileID
        self.filePath = filePath
        self.function = function
        self.line = line
        self.column = column
    }

    public func callAsFunction<Input: Sendable, Output: BytesRepresentable>(
        _ input: Input,
        for snapshot: Snapshot<Executor>
    ) async throws -> SnapshotFailure? where Executor == Async<Input, Output> {
        do {
            let diffable: Executor.Output

            if timeout > .zero {
                diffable = try await Task.timeout(timeout) {
                    try await snapshot.executor(input)
                }
            } else {
                diffable = try await snapshot.executor(input)
            }

            return try assert(
                diffable: diffable,
                pathExtension: snapshot.pathExtension,
                attachmentGenerator: snapshot.attachmentGenerator
            )
        } catch is TaskTimeout {
            return fail(
                reason: .timeout,
                snapshotURL: FileManager.default.temporaryDirectory,
                didWriteNewSnapshot: false
            )
        } catch {
            throw error
        }
    }

    public func callAsFunction<Input, Output: BytesRepresentable>(
        _ input: Input,
        for snapshot: Snapshot<Executor>
    ) throws -> SnapshotFailure? where Executor == Sync<Input, Output> {
        let dispatchGroup = DispatchGroup()
        let unsafeDiffable = UnsafeSyncDiffable<Output>()

        dispatchGroup.enter()
        snapshot.executor(input) { result in
            unsafeDiffable.result = result
            dispatchGroup.leave()
        }

        let result = dispatchGroup.wait(
            timeout: .now() + .nanoseconds(Int(timeout * 1_000_000_000))
        )

        switch result {
        case .success:
            return try assert(
                diffable: unsafeDiffable.result.get(),
                pathExtension: snapshot.pathExtension,
                attachmentGenerator: snapshot.attachmentGenerator
            )
        case .timedOut:
            return fail(
                reason: .timeout,
                snapshotURL: FileManager.default.temporaryDirectory,
                didWriteNewSnapshot: false
            )
        }
    }
}

extension SnapshotTester {

    fileprivate func assert(
        diffable: Executor.Output,
        pathExtension: String?,
        attachmentGenerator: any DiffAttachmentGenerator<Executor.Output>
    ) throws -> SnapshotFailure? {
        let snapshotURL = try snapshotURL(
            pathExtension: pathExtension
        )

        guard record == .all else {
            return try assertWithReference(
                diffable: diffable,
                snapshotURL: snapshotURL,
                attachmentGenerator: attachmentGenerator
            )
        }

        try record(
            diffable,
            url: snapshotURL,
            write: true,
            attachments: nil
        )

        return fail(
            reason: .allRecordMode,
            snapshotURL: snapshotURL,
            didWriteNewSnapshot: true
        )
    }

    private func assertWithReference(
        diffable: Executor.Output,
        snapshotURL: URL,
        attachmentGenerator: any DiffAttachmentGenerator<Executor.Output>
    ) throws -> SnapshotFailure? {
        guard !engine.contentExists(at: snapshotURL) else {
            return try compare(
                reference: engine.loadSnapshot(from: snapshotURL, using: self),
                diffable: diffable,
                snapshotURL: snapshotURL,
                attachmentGenerator: attachmentGenerator
            )
        }

        try record(
            diffable,
            url: snapshotURL,
            write: record == .missing,
            attachments: nil
        )

        return fail(
            reason: .missing,
            snapshotURL: snapshotURL,
            didWriteNewSnapshot: record == .missing
        )
    }

    private func compare(
        reference: Executor.Output,
        diffable: Executor.Output,
        snapshotURL: URL,
        attachmentGenerator: any DiffAttachmentGenerator<Executor.Output>
    ) throws -> SnapshotFailure? {
        guard
            let messageAttachment = attachmentGenerator(
                from: reference,
                with: diffable
            )
        else {
            try notify(diffable, to: snapshotURL)
            return nil
        }

        let failedURL: URL?

        if let temporaryURL = try engine.temporaryURL(for: filePath, using: self), record != .failed {
            let url = temporaryURL.appendingPathComponent(snapshotURL.lastPathComponent)

            try engine.perform(
                .write,
                contents: serialization.serialize(diffable),
                to: url,
                using: self
            )

            failedURL = url
        } else {
            failedURL = nil
        }

        try record(
            diffable,
            url: snapshotURL,
            write: record == .failed,
            attachments: messageAttachment.attachments
        )

        return fail(
            reason: .doesNotMatch,
            snapshotURL: snapshotURL,
            diff: failedURL.map {
                SnapshotEnvironment.current.diffTool(
                    currentFilePath: snapshotURL.absoluteString,
                    failedFilePath: $0.absoluteString
                )
            },
            additionalInformation: messageAttachment.message,
            didWriteNewSnapshot: record == .failed
        )
    }

    private func notify(
        _ diffable: Executor.Output,
        to url: URL
    ) throws {
        let diffableData = try serialization.serialize(diffable)

        try engine.perform(
            .notify,
            contents: diffableData,
            to: url,
            using: self
        )
    }

    private func record(
        _ diffable: Executor.Output,
        url: URL,
        write: Bool,
        attachments: [SnapshotAttachment]?
    ) throws {
        let diffableData = try serialization.serialize(diffable)

        try engine.perform(
            write ? .write : .notify,
            contents: diffableData,
            to: url,
            using: self
        )

        if let attachments {
            add("Attached Failure Diff", attachments: attachments)
        } else {
            add(diffableData, for: url)
        }
    }

    private func fail(
        reason: SnapshotFailContext.Reason,
        snapshotURL: URL,
        diff: String? = nil,
        additionalInformation: String? = nil,
        didWriteNewSnapshot: Bool
    ) -> SnapshotFailure {
        let context = SnapshotFailContext(
            function: function,
            reason: reason,
            url: snapshotURL,
            diff: diff,
            additionalInformation: additionalInformation,
            didWriteNewSnapshot: didWriteNewSnapshot
        )

        return SnapshotFailure(
            message: engine.generateFailureMessage(for: context, using: self),
            context: context
        )
    }
}

// MARK: - Source URL

extension SnapshotTester {

    fileprivate func snapshotURL(
        pathExtension: String?
    ) throws -> URL {
        let sourceURL = try engine.sourceURL(for: filePath, using: self)
        let function = String(describing: function).sanitizingPathComponent()

        let uniqueID: String

        if let name {
            uniqueID = name.sanitizingPathComponent()
        } else {
            uniqueID = self.uniqueID(function, at: sourceURL)
        }

        let snapshotURL = sourceURL.appendingPathComponent(
            function + "." + uniqueID
        )

        guard let pathExtension else {
            return snapshotURL
        }

        return snapshotURL.appendingPathExtension(pathExtension)
    }

    private func uniqueID(_ function: String, at url: URL) -> String {
        String(
            TestingSession.shared.functionPosition(
                fileID: fileID,
                filePath: filePath,
                function: function,
                line: line,
                column: column
            )
        )
    }
}

// MARK: - Attachments

extension SnapshotTester {

    func add(_ named: String, attachments: [SnapshotAttachment]) {
        TestingSystem.shared.add(
            named,
            attachments: attachments,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }

    func add(
        _ diffable: Data,
        for url: URL
    ) {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS) || os(macOS)
        let attachment = SnapshotAttachment(
            uniformTypeIdentifier: url.pathExtension.uniformTypeIdentifier(),
            name: url.lastPathComponent,
            payload: diffable
        )
        #else
        let attachment = SnapshotAttachment(
            uniformTypeIdentifier: "public.\(url.pathExtension)",
            name: url.lastPathComponent,
            payload: diffable
        )
        #endif

        TestingSystem.shared.add(
            "Attached Recorded Snapshot",
            attachments: [attachment],
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }
}

struct UnsafeSyncDiffableError: Error {}

final class UnsafeSyncDiffable<Output: Sendable>: @unchecked Sendable {

    var result: Result<Output, Error> {
        get { lock.withLock { _result } }
        set { lock.withLock { _result = newValue } }
    }

    private let lock = NSLock()
    private var _result: Result<Output, Error>

    init() {
        self._result = .failure(UnsafeSyncDiffableError())
    }
}
