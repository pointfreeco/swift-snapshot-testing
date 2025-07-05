import Foundation

@_spi(Internals)
public protocol SnapshotEngine<Executor>: Sendable where Executor.Output: BytesRepresentable {

    associatedtype Executor: SnapshotExecutor

    func sourceURL(
        for filePath: StaticString,
        using tester: SnapshotTester<Self>
    ) throws -> URL

    func temporaryURL(
        for filePath: StaticString,
        using tester: SnapshotTester<Self>
    ) throws -> URL?

    func contentExists(
        at url: URL
    ) -> Bool

    func loadSnapshot(
        from url: URL,
        using tester: SnapshotTester<Self>
    ) throws -> Executor.Output

    func perform(
        _ operation: SnapshotPerformOperation,
        contents: Data,
        to url: URL,
        using tester: SnapshotTester<Self>
    ) throws

    func generateFailureMessage(
        for context: SnapshotFailContext,
        using tester: SnapshotTester<Self>
    ) -> String
}
