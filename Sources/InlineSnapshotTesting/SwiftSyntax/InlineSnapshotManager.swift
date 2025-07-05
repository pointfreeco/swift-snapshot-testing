#if canImport(SwiftSyntax601)
import Foundation
import SwiftSyntax
import SwiftParser

final class InlineSnapshotManager: @unchecked Sendable {

    static var current: InlineSnapshotManager {
        local ?? shared
    }

    @TaskLocal
    fileprivate static var local: InlineSnapshotManager?

    private static let shared = InlineSnapshotManager()

    private let lock = NSLock()

    private var _snapshots: [URL: InlineSnapshot] = [:]
    private var _testSourceCache: [SnapshotURL: TestSource] = [:]

    fileprivate init() {}

    subscript(_ url: SnapshotURL) -> TestSource? {
        lock.withLock {
            _testSourceCache[url]
        }
    }

    func registerTestSource(_ url: SnapshotURL) throws {
        try lock.withLock {
            if _testSourceCache[url] != nil {
                return
            }

            let path = String(describing: url.path)

            let source = try String(contentsOfFile: path)

            let sourceFile = Parser.parse(source: source)

            let sourceLocationConverter = SourceLocationConverter(
                fileName: path,
                tree: sourceFile
            )

            let testSource = TestSource(
                source: source,
                sourceFile: sourceFile,
                sourceLocationConverter: sourceLocationConverter
            )

            _testSourceCache[url] = testSource
        }
    }

    func write(_ snapshot: InlineSnapshot, to url: URL) {
        lock.withLock {
            _snapshots[url] = snapshot
        }
    }

    func record(at url: URL) throws -> InlineSnapshot {
        try lock.withLock {
            guard let snapshot = _snapshots[url] else {
                throw URLError(.fileDoesNotExist)
            }

            return snapshot
        }
    }

    func recordExists(
        at url: URL
    ) -> Bool {
        lock.withLock {
            _snapshots[url] != nil
        }
    }

    func writeInlineSnapshots() {
        lock.withLock {
            while let (url, testSource) = _testSourceCache.popFirst() {
                _writeInlineSnapshots(
                    _records(for: url.path),
                    at: url,
                    testSource: testSource
                )
            }
        }
    }

    func writeInlineSnapshots(for testName: String) {
        lock.withLock {
            for (snapshotURL, testSource) in _testSourceCache {
                let url = URL(
                    fileURLWithPath: String(describing: snapshotURL.path)
                )

                guard url.lastPathComponent == testName else {
                    continue
                }

                _testSourceCache[snapshotURL] = nil

                return _writeInlineSnapshots(
                    _records(for: snapshotURL.path),
                    at: snapshotURL,
                    testSource: testSource
                )
            }
        }
    }

    func records(for filePath: StaticString) -> [InlineSnapshot] {
        lock.withLock {
            _records(for: filePath)
        }
    }

    // MARK: - Unsafe methods

    private func _records(for filePath: StaticString) -> [InlineSnapshot] {
        let url = URL(fileURLWithPath: String(describing: filePath))

        var records = [InlineSnapshot]()
        for (snapshotURL, snapshot) in _snapshots
        where snapshotURL.absoluteString.starts(with: url.absoluteString) {
            records.append(snapshot)
        }
        return records
    }

    private func _writeInlineSnapshots(
        _ snapshots: [InlineSnapshot],
        at url: SnapshotURL,
        testSource: TestSource
    ) {
        for snapshot in snapshots {
            let line = snapshot.line

            let snapshotRewriter = SnapshotRewriter(
                file: url,
                snapshots: snapshots.sorted {
                    $0.line != $1.line
                        ? $0.line < $1.line
                        : $0.closureDescriptor.trailingClosureOffset
                            < $1.closureDescriptor.trailingClosureOffset
                },
                sourceLocationConverter: testSource.sourceLocationConverter
            )

            let updatedSource = snapshotRewriter.visit(testSource.sourceFile).description

            if testSource.source != updatedSource {
                do {
                    try updatedSource.write(
                        toFile: String(describing: url.path),
                        atomically: true,
                        encoding: .utf8
                    )
                } catch {
                    fatalError("Threw error: \(error)", file: url.path, line: line)
                }
            }
        }
    }

    deinit {
        writeInlineSnapshots()
    }
}

@_spi(Internals)
public func withInlineSnapshotManager<R: Sendable>(
    _ operation: () async throws -> R,
    isolation: isolated Actor? = #isolation,
    file: String = #file,
    line: UInt = #line
) async rethrows -> R {
    try await InlineSnapshotManager.$local.withValue(
        InlineSnapshotManager(),
        operation: operation,
        isolation: isolation,
        file: file,
        line: line
    )
}

@_spi(Internals)
public func withInlineSnapshotManager<R>(
    _ operation: () throws -> R,
    file: String = #file,
    line: UInt = #line
) rethrows -> R {
    try InlineSnapshotManager.$local.withValue(
        InlineSnapshotManager(),
        operation: operation,
        file: file,
        line: line
    )
}
#endif
