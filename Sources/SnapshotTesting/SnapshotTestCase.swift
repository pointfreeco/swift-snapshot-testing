import XCTest

open class SnapshotTestCase: XCTestCase {
  private var counter = 1
  open var record = false
  open var diffTool: String? = nil

  public func assertSnapshot<A: DefaultDiffable>(
    matching snapshot: A,
    named name: String? = nil,
    record recording: Bool = false,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    function: String = #function,
    line: UInt = #line)
    where A.A == A
  {
    return assertSnapshot(
      of: A.defaultStrategy,
      matching: snapshot,
      named: name,
      record: recording,
      timeout: timeout,
      file: file,
      function: function,
      line: line
    )
  }

  public func assertSnapshot<A, B>(
    of strategy: Strategy<A, B>,
    matching value: A,
    named name: String? = nil,
    record recording: Bool = false,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    function: String = #function,
    line: UInt = #line
    ) {

    let recording = recording || self.record

    do {
      let snapshotDirectoryUrl: URL = {
        let fileUrl = URL(fileURLWithPath: "\(file)")
        let directoryUrl = fileUrl.deletingLastPathComponent()
        return directoryUrl
          .appendingPathComponent("__Snapshots__")
          .appendingPathComponent(fileUrl.deletingPathExtension().lastPathComponent)
      }()

      let identifier: String
      if let name = name {
        identifier = name
      } else {
        identifier = String(counter)
        counter += 1
      }

      let snapshotFileUrl = snapshotDirectoryUrl
        .appendingPathComponent("\(function.dropLast(2)).\(identifier)")
        .appendingPathExtension(strategy.pathExtension ?? "")
      let fileManager = FileManager.default
      try fileManager.createDirectory(at: snapshotDirectoryUrl, withIntermediateDirectories: true)

      let tookSnapshot = self.expectation(description: "Took snapshot")
      var optionalDiffable: B?
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
      try fileManager.createDirectory(at: artifactsUrl, withIntermediateDirectories: true)
      let failedSnapshotFileUrl = artifactsUrl.appendingPathComponent(snapshotFileUrl.lastPathComponent)
      try strategy.diffable.to(diffable).write(to: failedSnapshotFileUrl)

      if !attachments.isEmpty {
        #if Xcode
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
