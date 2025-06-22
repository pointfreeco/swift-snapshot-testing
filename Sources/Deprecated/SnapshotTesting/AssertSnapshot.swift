import XCTest

#if canImport(Testing)
  import Testing
#endif

/// Enhances failure messages with a command line diff tool expression that can be copied and pasted
/// into a terminal.
@available(*, deprecated, renamed: "TestingSession.shared.diffTool")
public var diffTool: SnapshotTestingConfiguration.DiffTool {
  get {
    _diffTool
  }
  set { _diffTool = newValue }
}

@available(*, deprecated, renamed: "TestingSession.shared.diffTool")
@_spi(Internals)
public var _diffTool: SnapshotTestingConfiguration.DiffTool {
  get {
    #if canImport(Testing)
      if let test = Test.current {
        for trait in test.traits.reversed() {
          if let diffTool = (trait as? _SnapshotsTestTrait)?.configuration.diffTool {
            return diffTool
          }
        }
      }
    #endif
    return __diffTool
  }
  set {
    __diffTool = newValue
  }
}

@available(*, deprecated, renamed: "TestingSession.shared.diffTool")
@_spi(Internals)
public var __diffTool: SnapshotTestingConfiguration.DiffTool = .default

/// Whether or not to record all new references.
@available(*, deprecated, renamed: "TestingSession.shared.record")
public var isRecording: Bool {
  get { SnapshotTestingConfiguration.current?.record ?? _record == .all }
  set { _record = newValue ? .all : .missing }
}

@available(*, deprecated, renamed: "TestingSession.shared.record")
@_spi(Internals)
public var _record: SnapshotTestingConfiguration.Record {
  get {
    #if canImport(Testing)
      if let test = Test.current {
        for trait in test.traits.reversed() {
          if let record = (trait as? _SnapshotsTestTrait)?.configuration.record {
            return record
          }
        }
      }
    #endif
    return __record
  }
  set {
    __record = newValue
  }
}

@available(*, deprecated, renamed: "TestingSession.shared.record")
@_spi(Internals)
public var __record: SnapshotTestingConfiguration.Record = {
  if let value = ProcessInfo.processInfo.environment["SNAPSHOT_TESTING_RECORD"],
    let record = SnapshotTestingConfiguration.Record(rawValue: value)
  {
    return record
  }
  return .missing
}()

/// Asserts that a given value matches a reference on disk.
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - snapshotting: A strategy for serializing, deserializing, and comparing values.
///   - name: An optional description of the snapshot.
///   - recording: Whether or not to record a new reference.
///   - timeout: The amount of time a snapshot must be generated in.
///   - fileID: The file ID in which failure occurred. Defaults to the file ID of the test case in
///     which this function was called.
///   - file: The file in which failure occurred. Defaults to the file path of the test case in
///     which this function was called.
///   - testName: The name of the test in which failure occurred. Defaults to the function name of
///     the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this
///     function was called.
///   - column: The column on which failure occurred. Defaults to the column on which this function
///     was called.
@available(
  *, deprecated, renamed: "assert(of:as:named:record:timeout:fileID:file:testName:line:column:)"
)
public func assertSnapshot<Value, Format>(
  of value: @autoclosure () throws -> Value,
  as snapshotting: Snapshotting<Value, Format>,
  named name: String? = nil,
  record recording: Bool? = nil,
  timeout: TimeInterval = 5,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  testName: String = #function,
  line: UInt = #line,
  column: UInt = #column
) {
  let failure = verifySnapshot(
    of: try value(),
    as: snapshotting,
    named: name,
    record: recording,
    timeout: timeout,
    fileID: fileID,
    file: filePath,
    testName: testName,
    line: line,
    column: column
  )
  guard let message = failure else { return }
  recordIssue(
    message,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
}

/// Asserts that a given value matches references on disk.
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - strategies: A dictionary of names and strategies for serializing, deserializing, and
///     comparing values.
///   - recording: Whether or not to record a new reference.
///   - timeout: The amount of time a snapshot must be generated in.
///   - fileID: The file ID in which failure occurred. Defaults to the file ID of the test case in
///     which this function was called.
///   - file: The file in which failure occurred. Defaults to the file path of the test case in
///     which this function was called.
///   - testName: The name of the test in which failure occurred. Defaults to the function name of
///     the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this
///     function was called.
///   - column: The column on which failure occurred. Defaults to the column on which this function
///     was called.
@available(*, deprecated, renamed: "assert(of:as:record:timeout:fileID:file:testName:line:column:)")
public func assertSnapshots<Value, Format>(
  of value: @autoclosure () throws -> Value,
  as strategies: [String: Snapshotting<Value, Format>],
  record recording: Bool? = nil,
  timeout: TimeInterval = 5,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  testName: String = #function,
  line: UInt = #line,
  column: UInt = #column
) {
  try? strategies.forEach { name, strategy in
    assertSnapshot(
      of: try value(),
      as: strategy,
      named: name,
      record: recording,
      timeout: timeout,
      fileID: fileID,
      file: filePath,
      testName: testName,
      line: line,
      column: column
    )
  }
}

/// Asserts that a given value matches references on disk.
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - strategies: An array of strategies for serializing, deserializing, and comparing values.
///   - recording: Whether or not to record a new reference.
///   - timeout: The amount of time a snapshot must be generated in.
///   - fileID: The file ID in which failure occurred. Defaults to the file ID of the test case in
///     which this function was called.
///   - file: The file in which failure occurred. Defaults to the file path of the test case in
///     which this function was called.
///   - testName: The name of the test in which failure occurred. Defaults to the function name of
///     the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this
///     function was called.
///   - column: The column on which failure occurred. Defaults to the column on which this function
///     was called.
@available(*, deprecated, renamed: "assert(of:as:record:timeout:fileID:file:testName:line:column:)")
public func assertSnapshots<Value, Format>(
  of value: @autoclosure () throws -> Value,
  as strategies: [Snapshotting<Value, Format>],
  record recording: Bool? = nil,
  timeout: TimeInterval = 5,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  testName: String = #function,
  line: UInt = #line,
  column: UInt = #column
) {
  try? strategies.forEach { strategy in
    assertSnapshot(
      of: try value(),
      as: strategy,
      record: recording,
      timeout: timeout,
      fileID: fileID,
      file: filePath,
      testName: testName,
      line: line,
      column: column
    )
  }
}

/// Verifies that a given value matches a reference on disk.
///
/// Third party snapshot assert helpers can be built on top of this function. Simply invoke
/// `verifySnapshot` with your own arguments, and then invoke `XCTFail` with the string returned if
/// it is non-`nil`. For example, if you want the snapshot directory to be determined by an
/// environment variable, you can create your own assert helper like so:
///
/// ```swift
/// public func myAssertSnapshot<Value, Format>(
///   of value: @autoclosure () throws -> Value,
///   as snapshotting: Snapshotting<Value, Format>,
///   named name: String? = nil,
///   record recording: Bool = false,
///   timeout: TimeInterval = 5,
///   file: StaticString = #file,
///   testName: String = #function,
///   line: UInt = #line
///   ) {
///
///     let snapshotDirectory = ProcessInfo.processInfo.environment["SNAPSHOT_REFERENCE_DIR"]! + "/" + #file
///     let failure = verifySnapshot(
///       of: value,
///       as: snapshotting,
///       named: name,
///       record: recording,
///       snapshotDirectory: snapshotDirectory,
///       timeout: timeout,
///       file: file,
///       testName: testName
///     )
///     guard let message = failure else { return }
///     XCTFail(message, file: file, line: line)
/// }
/// ```
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - snapshotting: A strategy for serializing, deserializing, and comparing values.
///   - name: An optional description of the snapshot.
///   - recording: Whether or not to record a new reference.
///   - snapshotDirectory: Optional directory to save snapshots. By default snapshots will be saved
///     in a directory with the same name as the test file, and that directory will sit inside a
///     directory `__Snapshots__` that sits next to your test file.
///   - timeout: The amount of time a snapshot must be generated in.
///   - file: The file in which failure occurred. Defaults to the file name of the test case in
///     which this function was called.
///   - testName: The name of the test in which failure occurred. Defaults to the function name of
///     the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this
///     function was called.
/// - Returns: A failure message or, if the value matches, nil.
@available(
  *, deprecated,
  renamed: "verify(of:as:named:record:snapshotDirectory:timeout:fileID:file:testName:line:column:)"
)
public func verifySnapshot<Value, Format>(
  of value: @autoclosure () throws -> Value,
  as snapshotting: Snapshotting<Value, Format>,
  named name: String? = nil,
  record recording: Bool? = nil,
  snapshotDirectory: String? = nil,
  timeout: TimeInterval = 5,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #file,
  testName: String = #function,
  line: UInt = #line,
  column: UInt = #column
) -> String? {
  #if canImport(Testing)
    if Test.current == nil {
      CleanCounterBetweenTestCases.registerIfNeeded()
    }
  #else
    CleanCounterBetweenTestCases.registerIfNeeded()
  #endif

  let record =
    (recording == true ? .all : recording == false ? .missing : nil)
    ?? SnapshotTestingConfiguration.current?.record
    ?? _record
  return withSnapshotTesting(record: record) { () -> String? in
    do {
      let fileUrl = URL(fileURLWithPath: "\(filePath)", isDirectory: false)
      let fileName = fileUrl.deletingPathExtension().lastPathComponent

      #if os(Android)
        // When running tests on Android, the CI script copies the Tests/SnapshotTestingTests/__Snapshots__ up to the temporary folder
        let snapshotsBaseUrl = URL(
          fileURLWithPath: "/data/local/tmp/android-xctest", isDirectory: true)
      #else
        let snapshotsBaseUrl = fileUrl.deletingLastPathComponent()
      #endif

      let snapshotDirectoryUrl =
        snapshotDirectory.map { URL(fileURLWithPath: $0, isDirectory: true) }
        ?? snapshotsBaseUrl.appendingPathComponent("__Snapshots__").appendingPathComponent(fileName)

      let identifier: String
      if let name = name {
        identifier = sanitizePathComponent(name)
      } else {
        identifier = String(
          counter.next(for: snapshotDirectoryUrl.appendingPathComponent(testName).absoluteString)
        )
      }

      let testName = sanitizePathComponent(testName)
      var snapshotFileUrl =
        snapshotDirectoryUrl
        .appendingPathComponent("\(testName).\(identifier)")
      if let ext = snapshotting.pathExtension {
        snapshotFileUrl = snapshotFileUrl.appendingPathExtension(ext)
      }
      let fileManager = FileManager.default
      try fileManager.createDirectory(at: snapshotDirectoryUrl, withIntermediateDirectories: true)

      let tookSnapshot = XCTestExpectation(description: "Took snapshot")
      var optionalDiffable: Format?
      snapshotting.snapshot(try value()).run { b in
        optionalDiffable = b
        tookSnapshot.fulfill()
      }
      let result = XCTWaiter.wait(for: [tookSnapshot], timeout: timeout)
      switch result {
      case .completed:
        break
      case .timedOut:
        return """
          Exceeded timeout of \(timeout) seconds waiting for snapshot.

          This can happen when an asynchronously rendered view (like a web view) has not loaded. \
          Ensure that every subview of the view hierarchy has loaded to avoid timeouts, or, if a \
          timeout is unavoidable, consider setting the "timeout" parameter of "assertSnapshot" to \
          a higher value.
          """
      case .incorrectOrder, .invertedFulfillment, .interrupted:
        return "Couldn't snapshot value"
      @unknown default:
        return "Couldn't snapshot value"
      }

      guard var diffable = optionalDiffable else {
        return "Couldn't snapshot value"
      }

      func recordSnapshot(writeToDisk: Bool) throws {
        let snapshotData = snapshotting.diffing.toData(diffable)

        if writeToDisk {
          try snapshotData.write(to: snapshotFileUrl)
        }

        #if !os(Android) && !os(Linux) && !os(Windows)
          if !isSwiftTesting,
            ProcessInfo.processInfo.environment.keys.contains("__XCODE_BUILT_PRODUCTS_DIR_PATHS")
          {
            XCTContext.runActivity(named: "Attached Recorded Snapshot") { activity in
              if writeToDisk {
                // Snapshot was written to disk. Create attachment from file
                let attachment = XCTAttachment(contentsOfFile: snapshotFileUrl)
                activity.add(attachment)
              } else {
                // Snapshot was not written to disk. Create attachment from data and path extension
                let typeIdentifier = snapshotting.pathExtension.flatMap(
                  uniformTypeIdentifier(fromExtension:))

                let attachment = XCTAttachment(
                  uniformTypeIdentifier: typeIdentifier,
                  name: snapshotFileUrl.lastPathComponent,
                  payload: snapshotData
                )

                activity.add(attachment)
              }
            }
          }
        #endif
      }

      if record == .all {
        try recordSnapshot(writeToDisk: true)

        return """
          Record mode is on. Automatically recorded snapshot: …

          open "\(snapshotFileUrl.absoluteString)"

          Turn record mode off and re-run "\(testName)" to assert against the newly-recorded snapshot
          """
      }

      guard fileManager.fileExists(atPath: snapshotFileUrl.path) else {
        if record == .never {
          try recordSnapshot(writeToDisk: false)

          return """
            No reference was found on disk. New snapshot was not recorded because recording is disabled
            """
        } else {
          try recordSnapshot(writeToDisk: true)

          return """
            No reference was found on disk. Automatically recorded snapshot: …

            open "\(snapshotFileUrl.absoluteString)"

            Re-run "\(testName)" to assert against the newly-recorded snapshot.
            """
        }
      }

      let data = try Data(contentsOf: snapshotFileUrl)
      let reference = snapshotting.diffing.fromData(data)

      #if os(iOS) || os(tvOS)
        // If the image generation fails for the diffable part and the reference was empty, use the reference
        if let localDiff = diffable as? UIImage,
          let refImage = reference as? UIImage,
          localDiff.size == .zero && refImage.size == .zero
        {
          diffable = reference
        }
      #endif

      guard let (failure, attachments) = snapshotting.diffing.diff(reference, diffable) else {
        return nil
      }

      let artifactsUrl = URL(
        fileURLWithPath: ProcessInfo.processInfo.environment["SNAPSHOT_ARTIFACTS"]
          ?? NSTemporaryDirectory(), isDirectory: true
      )
      let artifactsSubUrl = artifactsUrl.appendingPathComponent(fileName)
      try fileManager.createDirectory(at: artifactsSubUrl, withIntermediateDirectories: true)
      let failedSnapshotFileUrl = artifactsSubUrl.appendingPathComponent(
        snapshotFileUrl.lastPathComponent)
      try snapshotting.diffing.toData(diffable).write(to: failedSnapshotFileUrl)

      if !attachments.isEmpty {
        #if !os(Linux) && !os(Android) && !os(Windows)
          if ProcessInfo.processInfo.environment.keys.contains("__XCODE_BUILT_PRODUCTS_DIR_PATHS"),
            !isSwiftTesting
          {
            XCTContext.runActivity(named: "Attached Failure Diff") { activity in
              attachments.forEach {
                activity.add($0)
              }
            }
          }
        #endif
      }

      let diffMessage = (SnapshotTestingConfiguration.current?.diffTool ?? _diffTool)(
        currentFilePath: snapshotFileUrl.path,
        failedFilePath: failedSnapshotFileUrl.path
      )

      var failureMessage: String
      if let name = name {
        failureMessage = "Snapshot \"\(name)\" does not match reference."
      } else {
        failureMessage = "Snapshot does not match reference."
      }

      if record == .failed {
        try recordSnapshot(writeToDisk: true)
        failureMessage += " A new snapshot was automatically recorded."
      }

      return """
        \(failureMessage)

        \(diffMessage)

        \(failure.trimmingCharacters(in: .whitespacesAndNewlines))
        """
    } catch {
      return error.localizedDescription
    }
  }
}

// MARK: - Private

private var counter: File.Counter {
  #if canImport(Testing)
    if Test.current != nil {
      return File.counter
    } else {
      return _counter
    }
  #else
    return _counter
  #endif
}

private let _counter = File.Counter()

func sanitizePathComponent(_ string: String) -> String {
  return
    string
    .replacingOccurrences(of: "\\W+", with: "-", options: .regularExpression)
    .replacingOccurrences(of: "^-|-$", with: "", options: .regularExpression)
}

#if !os(Android) && !os(Linux) && !os(Windows)
  import CoreServices

  func uniformTypeIdentifier(fromExtension pathExtension: String) -> String? {
    // This can be much cleaner in macOS 11+ using UTType
    let unmanagedString = UTTypeCreatePreferredIdentifierForTag(
      kUTTagClassFilenameExtension as CFString,
      pathExtension as CFString,
      nil
    )

    return unmanagedString?.takeRetainedValue() as String?
  }
#endif

// We need to clean counter between tests executions in order to support test-iterations.
private class CleanCounterBetweenTestCases: NSObject, XCTestObservation {
  private static var registered = false

  static func registerIfNeeded() {
    guard !registered else { return }
    defer { registered = true }
    if Thread.isMainThread {
      XCTestObservationCenter.shared.addTestObserver(CleanCounterBetweenTestCases())
    } else {
      DispatchQueue.main.sync {
        XCTestObservationCenter.shared.addTestObserver(CleanCounterBetweenTestCases())
      }
    }
  }

  func testCaseDidFinish(_ testCase: XCTestCase) {
    _counter.reset()
  }
}

enum File {
  @TaskLocal static var counter = Counter()

  final class Counter: @unchecked Sendable {
    private var counts: [String: Int] = [:]
    private let lock = NSLock()

    init() {}

    func next(for key: String) -> Int {
      lock.lock()
      defer { lock.unlock() }
      counts[key, default: 0] += 1
      return counts[key]!
    }

    func reset() {
      lock.lock()
      defer { lock.unlock() }
      counts.removeAll()
    }
  }
}
