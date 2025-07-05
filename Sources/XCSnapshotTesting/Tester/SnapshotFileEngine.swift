import Foundation

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS) || os(visionOS)
import CoreServices
import UniformTypeIdentifiers
#endif

struct SnapshotFileEngine<Executor: SnapshotExecutor>: SnapshotEngine
where Executor.Output: BytesRepresentable {

    let sourceURL: URL?

    func sourceURL(
        for filePath: StaticString,
        using tester: SnapshotTester<SnapshotFileEngine<Executor>>
    ) throws -> URL {
        let fileURL = URL(
            fileURLWithPath: String(describing: filePath),
            isDirectory: false
        )

        var sourceURL =
            sourceURL
            ?? snapshotURL(
                fileURL.deletingLastPathComponent(),
                at: "__Snapshots__",
                using: tester
            )

        sourceURL.appendPathComponent(fileURL.deletingPathExtension().lastPathComponent)

        try FileManager.default.createDirectory(
            at: sourceURL,
            withIntermediateDirectories: true
        )

        return sourceURL
    }

    func temporaryURL(
        for filePath: StaticString,
        using tester: SnapshotTester<SnapshotFileEngine<Executor>>
    ) throws -> URL? {
        let fileURL = URL(
            fileURLWithPath: String(describing: filePath),
            isDirectory: false
        )

        var snapshotURL = snapshotURL(
            ProcessInfo.artifactsDirectory,
            at: "Snapshots",
            using: tester
        )

        snapshotURL.appendPathComponent(fileURL.deletingPathExtension().lastPathComponent)

        try FileManager.default.createDirectory(
            at: snapshotURL,
            withIntermediateDirectories: true
        )

        return snapshotURL
    }

    func contentExists(at url: URL) -> Bool {
        url.isFileURL && FileManager.default.fileExists(atPath: url.path)
    }

    func loadSnapshot(
        from url: URL,
        using tester: SnapshotTester<SnapshotFileEngine<Executor>>
    ) throws -> Executor.Output {
        try tester.serialization.deserialize(
            Executor.Output.self,
            from: Data(contentsOf: url)
        )
    }

    func perform(
        _ operation: SnapshotPerformOperation,
        contents: Data,
        to url: URL,
        using tester: SnapshotTester<SnapshotFileEngine<Executor>>
    ) throws {
        guard case .write = operation else {
            return
        }

        try contents.write(to: url, options: .atomic)
    }

    func generateFailureMessage(
        for context: SnapshotFailContext,
        using tester: SnapshotTester<SnapshotFileEngine<Executor>>
    ) -> String {
        switch context.reason {
        case .missing:
            return missing(context)
        case .doesNotMatch:
            return doesNotMatch(context)
        case .allRecordMode:
            return allRecordMode(context)
        case .timeout:
            return timeout(context, timeout: tester.timeout)
        }
    }
}

extension SnapshotFileEngine {

    fileprivate func snapshotURL(
        _ url: URL,
        at componentPath: String,
        using tester: SnapshotTester<SnapshotFileEngine<Executor>>
    ) -> URL {
        var snapshotsURL = url

        snapshotsURL.appendPathComponent(componentPath)

        if !tester.platform.isEmpty {
            snapshotsURL.appendPathComponent(tester.platform)
        }

        if let platformVersion = tester.platformVersion {
            snapshotsURL.appendPathComponent(platformVersion)
        }

        return snapshotsURL
    }
}

extension SnapshotFileEngine {

    fileprivate func missing(_ context: SnapshotFailContext) -> String {
        let name = String(describing: context.function)

        if context.didWriteNewSnapshot {
            return """
                No reference was found on disk. Automatically recorded snapshot: …

                open "\(context.url.absoluteString)"

                Re-run "\(name)" to assert against the newly-recorded snapshot.
                """
        } else {
            return
                "No reference was found on disk. New snapshot was not recorded because recording is disabled"
        }
    }

    fileprivate func doesNotMatch(_ context: SnapshotFailContext) -> String {
        let name = String(describing: context.function)

        var message = "Snapshot \"\(name)\" does not match reference."

        if context.didWriteNewSnapshot {
            message += """
                 A new snapshot was automatically recorded.

                open "\(context.url.absoluteString)"
                """
        }

        if let diff = context.diff {
            message += "\n\n" + diff
        }

        if let additionalInformation = context.additionalInformation {
            message += "\n\n" + additionalInformation.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return message
    }

    fileprivate func allRecordMode(_ context: SnapshotFailContext) -> String {
        let name = String(describing: context.function)

        return """
            Record mode is on. Automatically recorded snapshot: …

            open "\(context.url.absoluteString)"

            Turn record mode off and re-run "\(name)" to assert against the newly-recorded snapshot
            """
    }

    fileprivate func timeout(_ context: SnapshotFailContext, timeout: TimeInterval) -> String {
        """
        Exceeded timeout of \(timeout) seconds waiting for snapshot.

        This can happen when an asynchronously rendered view (like a web view) has not loaded. \
        Ensure that every subview of the view hierarchy has loaded to avoid timeouts, or, if a \
        timeout is unavoidable, consider setting the "timeout" parameter of "assert" to \
        a higher value.
        """
    }
}
