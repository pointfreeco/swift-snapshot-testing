#if os(Linux)
import XCTest

open class SnapshotTestCase: XCTestCase {
  private var counter = 1
  open var record = false
  open var diffTool: String? = nil

  public func assertSnapshot<A: DefaultSnapshottable>(
    matching snapshot: A,
    named name: String? = nil,
    record recording: Bool = false,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line)
    where A.Snapshottable == A
  {
    return assertSnapshot(
      matching: snapshot,
      as: A.defaultStrategy,
      named: name,
      record: recording,
      timeout: timeout,
      file: file,
      testName: testName,
      line: line
    )
  }

  public func assertSnapshot<Snapshottable, Format>(
    matching value: Snapshottable,
    as strategy: Strategy<Snapshottable, Format>,
    named name: String? = nil,
    record recording: Bool = false,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
    ) {

    let recording = recording || self.record

    do {
      let fileUrl = URL(fileURLWithPath: "\(file)")
      let fileName = fileUrl.deletingPathExtension().lastPathComponent
      let directoryUrl = fileUrl.deletingLastPathComponent()
      let snapshotDirectoryUrl: URL = directoryUrl
        .appendingPathComponent("__Snapshots__")
        .appendingPathComponent(fileName)

      let identifier: String
      if let name = name {
        identifier = name
      } else {
        identifier = String(counter)
        counter += 1
      }

      let snapshotFileUrl = snapshotDirectoryUrl
        .appendingPathComponent("\(testName.dropLast(2)).\(identifier)")
        .appendingPathExtension(strategy.pathExtension ?? "")
      let fileManager = FileManager.default
      try fileManager.createDirectory(at: snapshotDirectoryUrl, withIntermediateDirectories: true)

      let tookSnapshot = self.expectation(description: "Took snapshot")
      var optionalDiffable: Format?
      strategy.snapshotToDiffable(value).run { b in
        optionalDiffable = b
        tookSnapshot.fulfill()
      }
      #if os(Linux)
      self.waitForExpectations(timeout: timeout)
      #else
      self.wait(for: [tookSnapshot], timeout: timeout)
      #endif

      guard let diffable = optionalDiffable else {
        XCTFail("Couldn't snapshot value", file: file, line: line)
        return
      }

      guard !recording, fileManager.fileExists(atPath: snapshotFileUrl.path) else {
        try strategy.diffable.to(diffable).write(to: snapshotFileUrl)
        XCTFail("Recorded snapshot: …\n\n\"\(snapshotFileUrl.path)\"", file: file, line: line)
        return
      }

      let data = try Data(contentsOf: snapshotFileUrl)
      let reference = strategy.diffable.fro(data)

      guard let (failure, attachments) = strategy.diffable.diff(reference, diffable) else {
        return
      }

      let artifactsUrl = URL(
        fileURLWithPath: ProcessInfo.processInfo.environment["SNAPSHOT_ARTIFACTS"] ?? NSTemporaryDirectory()
      )
      let artifactsSubUrl = artifactsUrl.appendingPathComponent(fileName)
      try fileManager.createDirectory(at: artifactsSubUrl, withIntermediateDirectories: true)
      let failedSnapshotFileUrl = artifactsSubUrl.appendingPathComponent(snapshotFileUrl.lastPathComponent)
      try strategy.diffable.to(diffable).write(to: failedSnapshotFileUrl)

      if !attachments.isEmpty {
        #if !os(Linux)
        XCTContext.runActivity(named: "Attached Failure Diff") { activity in
          attachments.forEach {
            activity.add($0.rawValue)
          }
        }
        #endif
      }

      let diffMessage = self.diffTool
        .map { "\($0) \"\(snapshotFileUrl.path)\" \"\(failedSnapshotFileUrl.path)\"" }
        ?? "@\(minus)\n\"\(snapshotFileUrl.path)\"\n@\(plus)\n\"\(failedSnapshotFileUrl.path)\""
      let message = """
      \(failure.trimmingCharacters(in: .whitespacesAndNewlines))

      \(diffMessage)
      """
      XCTFail(message, file: file, line: line)
    } catch {
      XCTFail(error.localizedDescription, file: file, line: line)
    }
  }
}
#endif
