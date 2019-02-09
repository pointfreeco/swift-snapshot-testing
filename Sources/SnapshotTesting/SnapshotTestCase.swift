import XCTest

#if !os(Linux)
@available(swift, obsoleted: 5.0, renamed: "XCTestCase", message: "Please use XCTestCase instead")
public typealias SnapshotTestCase = XCTestCase
#else

/// An XCTest subclass that provides snaphot testing helpers.
open class SnapshotTestCase: XCTestCase {
  /// Whether or not to record all new references.
  open var record = false

  /// Enhances failure messages with a command line expression that can be copied and pasted into a terminal.
  ///
  ///     diffTool = "ksdiff"
  open var diffTool: String? = nil

  /// Asserts that a given value matches a reference on disk.
  ///
  /// - Parameters:
  ///   - value: A value to compare against a reference.
  ///   - snapshotting: A strategy for serializing, deserializing, and comparing values.
  ///   - name: An optional description of the snapshot.
  ///   - recording: Whether or not to record a new reference.
  ///   - timeout: The amount of time a snapshot must be generated in.
  ///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
  ///   - testName: The name of the test in which failure occurred. Defaults to the function name of the test case in which this function was called.
  ///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
  public func assertSnapshot<Value, Format>(
    matching value: @autoclosure () throws -> Value,
    as snapshotting: Snapshotting<Value, Format>,
    named name: String? = nil,
    record recording: Bool = false,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
    ) {

    let failure = verifySnapshot(
      matching: value,
      as: snapshotting,
      named: name,
      record: recording,
      timeout: timeout,
      file: file,
      testName: testName,
      line: line
    )
    guard let message = failure else { return }
    XCTFail(message, file: file, line: line)
  }

  /// Asserts that a given value matches references on disk.
  ///
  /// - Parameters:
  ///   - value: A value to compare against a reference.
  ///   - snapshotting: An dictionnay of names and strategies for serializing, deserializing, and comparing values.
  ///   - recording: Whether or not to record a new reference.
  ///   - timeout: The amount of time a snapshot must be generated in.
  ///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
  ///   - testName: The name of the test in which failure occurred. Defaults to the function name of the test case in which this function was called.
  ///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
  public func assertSnapshots<Value, Format>(
    matching value: @autoclosure () throws -> Value,
    as strategies: [String: Snapshotting<Value, Format>],
    record recording: Bool = false,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
    ) {

    strategies.forEach { name, strategy in
      assertSnapshot(
        matching: value,
        as: strategy,
        named: name,
        record: recording,
        timeout: timeout,
        file: file,
        testName: testName,
        line: line
      )
    }
  }

  /// Asserts that a given value matches references on disk.
  ///
  /// - Parameters:
  ///   - value: A value to compare against a reference.
  ///   - snapshotting: An array of strategies for serializing, deserializing, and comparing values.
  ///   - recording: Whether or not to record a new reference.
  ///   - timeout: The amount of time a snapshot must be generated in.
  ///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
  ///   - testName: The name of the test in which failure occurred. Defaults to the function name of the test case in which this function was called.
  ///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
  public func assertSnapshots<Value, Format>(
    matching value: @autoclosure () throws -> Value,
    as strategies: [Snapshotting<Value, Format>],
    record recording: Bool = false,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
    ) {

    strategies.forEach { strategy in
      assertSnapshot(
        matching: value,
        as: strategy,
        record: recording,
        timeout: timeout,
        file: file,
        testName: testName,
        line: line
      )
    }
  }

  /// Verifies that a given value matches a reference on disk.
  ///
  /// - Parameters:
  ///   - value: A value to compare against a reference.
  ///   - snapshotting: A strategy for serializing, deserializing, and comparing values.
  ///   - name: An optional description of the snapshot.
  ///   - recording: Whether or not to record a new reference.
  ///   - timeout: The amount of time a snapshot must be generated in.
  ///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
  ///   - testName: The name of the test in which failure occurred. Defaults to the function name of the test case in which this function was called.
  ///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
  /// - Returns: A failure message or, if the value matches, nil.
  public func verifySnapshot<Value, Format>(
    matching value: @autoclosure () throws -> Value,
    as snapshotting: Snapshotting<Value, Format>,
    named name: String? = nil,
    record recording: Bool = false,
    snapshotDirectory: String? = nil,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
    )
    -> String? {

      let recording = recording || self.record

      do {
        let fileUrl = URL(fileURLWithPath: "\(file)")
        let fileName = fileUrl.deletingPathExtension().lastPathComponent

        let snapshotDirectoryUrl = snapshotDirectory.map(URL.init(fileURLWithPath:))
          ?? fileUrl
            .deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__")
            .appendingPathComponent(fileName)

        let identifier: String
        if let name = name {
          identifier = sanitizePathComponent(name)
        } else {
          identifier = String(counter)
          counter += 1
        }

        let testName = sanitizePathComponent(testName)
        let snapshotFileUrl = snapshotDirectoryUrl
          .appendingPathComponent("\(testName).\(identifier)")
          .appendingPathExtension(snapshotting.pathExtension ?? "")
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: snapshotDirectoryUrl, withIntermediateDirectories: true)

        let tookSnapshot = self.expectation(description: "Took snapshot")
        var optionalDiffable: Format?
        snapshotting.snapshot(try value()).run { b in
          optionalDiffable = b
          tookSnapshot.fulfill()
        }
        #if os(Linux)
        self.waitForExpectations(timeout: timeout)
        #else
        self.wait(for: [tookSnapshot], timeout: timeout)
        #endif

        guard let diffable = optionalDiffable else {
          return "Couldn't snapshot value"
        }

        guard !recording, fileManager.fileExists(atPath: snapshotFileUrl.path) else {
          let diffMessage = (try? Data(contentsOf: snapshotFileUrl))
            .flatMap { data in snapshotting.diffing.diff(snapshotting.diffing.fromData(data), diffable) }
            .map { diff, _ in diff.trimmingCharacters(in: .whitespacesAndNewlines) }
            ?? "Recorded snapshot: …"

          try snapshotting.diffing.toData(diffable).write(to: snapshotFileUrl)
          return recording
            ? """
              Record mode is on. Turn record mode off and re-run "\(testName)" to test against the newly-recorded snapshot.

              open "\(snapshotFileUrl.path)"

              \(diffMessage)
              """
            : """
          No reference was found on disk. Automatically recorded snapshot: …

          open "\(snapshotFileUrl.path)"

          Re-run "\(testName)" to test against the newly-recorded snapshot.
          """
        }

        let data = try Data(contentsOf: snapshotFileUrl)
        let reference = snapshotting.diffing.fromData(data)

        guard let (failure, attachments) = snapshotting.diffing.diff(reference, diffable) else {
          return nil
        }

        let artifactsUrl = URL(
          fileURLWithPath: ProcessInfo.processInfo.environment["SNAPSHOT_ARTIFACTS"] ?? NSTemporaryDirectory()
        )
        let artifactsSubUrl = artifactsUrl.appendingPathComponent(fileName)
        try fileManager.createDirectory(at: artifactsSubUrl, withIntermediateDirectories: true)
        let failedSnapshotFileUrl = artifactsSubUrl.appendingPathComponent(snapshotFileUrl.lastPathComponent)
        try snapshotting.diffing.toData(diffable).write(to: failedSnapshotFileUrl)

        if !attachments.isEmpty {
          #if !os(Linux)
          XCTContext.runActivity(named: "Attached Failure Diff") { activity in
            attachments.forEach {
              activity.add($0)
            }
          }
          #endif
        }

        let diffMessage = self.diffTool
          .map { "\($0) \"\(snapshotFileUrl.path)\" \"\(failedSnapshotFileUrl.path)\"" }
          ?? "@\(minus)\n\"\(snapshotFileUrl.path)\"\n@\(plus)\n\"\(failedSnapshotFileUrl.path)\""
        let message = """
        Snapshot does not match reference.

        \(diffMessage)

        \(failure.trimmingCharacters(in: .whitespacesAndNewlines))
        """
        return message
      } catch {
        return error.localizedDescription
      }
  }

  private var counter = 1
}
#endif
