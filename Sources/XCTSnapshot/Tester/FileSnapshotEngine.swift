import Foundation
@preconcurrency import XCTest
import UniformTypeIdentifiers
import CoreServices

struct FileSnapshotEngine<Executor: SnapshotExecutor>: SnapshotEngine where Executor.Output: BytesRepresentable {

  let sourceURL: URL?

  func sourceURL(
    for filePath: StaticString,
    using tester: SnapshotTester<FileSnapshotEngine<Executor>>
  ) throws -> URL {
    let fileURL = URL(
      fileURLWithPath: String(describing: filePath),
      isDirectory: false
    )

    let sourceURL = (sourceURL ?? {
      let folderURL = fileURL.deletingLastPathComponent()

      let snapshotsURL = folderURL
        .appendingPathComponent("__Snapshots__")

      if tester.platform.isEmpty {
        return snapshotsURL
      } else {
        return snapshotsURL.appendingPathComponent(tester.platform)
      }
    }()).appendingPathComponent(fileURL.deletingPathExtension().lastPathComponent)

    try FileManager.default.createDirectory(
      at: sourceURL,
      withIntermediateDirectories: true
    )

    return sourceURL
  }

  func temporaryURL(
    for filePath: StaticString,
    using tester: SnapshotTester<FileSnapshotEngine<Executor>>
  ) throws -> URL? {
    let fileURL = URL(
      fileURLWithPath: String(describing: filePath),
      isDirectory: false
    )

    var snapshotURL = ProcessInfo.artifactsDirectory
      .appendingPathComponent("Snapshots")

    if !tester.platform.isEmpty {
      snapshotURL.appendPathComponent(tester.platform)
    }

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
    using tester: SnapshotTester<FileSnapshotEngine<Executor>>
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
    using tester: SnapshotTester<FileSnapshotEngine<Executor>>
  ) throws {
    guard case .write = operation else {
      return
    }

    try contents.write(to: url, options: .atomic)
  }

  func generateFailureMessage(
    for context: SnapshotFailContext,
    using tester: SnapshotTester<FileSnapshotEngine<Executor>>
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

private extension FileSnapshotEngine {

  func missing(_ context: SnapshotFailContext) -> String {
    let name = String(describing: context.function)

    if context.didWriteNewSnapshot {
      return """
        No reference was found on disk. Automatically recorded snapshot: …
        
        open "\(context.url.absoluteString)"
        
        Re-run "\(name)" to assert against the newly-recorded snapshot.
        """
    } else {
      return "No reference was found on disk. New snapshot was not recorded because recording is disabled"
    }
  }

  func doesNotMatch(_ context: SnapshotFailContext) -> String {
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

  func allRecordMode(_ context: SnapshotFailContext) -> String {
    let name = String(describing: context.function)

    return """
      Record mode is on. Automatically recorded snapshot: …
      
      open "\(context.url.absoluteString)"
      
      Turn record mode off and re-run "\(name)" to assert against the newly-recorded snapshot
      """
  }

  func timeout(_ context: SnapshotFailContext, timeout: TimeInterval) -> String {
    """
    Exceeded timeout of \(timeout) seconds waiting for snapshot.

    This can happen when an asynchronously rendered view (like a web view) has not loaded. \
    Ensure that every subview of the view hierarchy has loaded to avoid timeouts, or, if a \
    timeout is unavoidable, consider setting the "timeout" parameter of "assert" to \
    a higher value.
    """
  }
}
