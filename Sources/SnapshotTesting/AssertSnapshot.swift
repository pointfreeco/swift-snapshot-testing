import XCTest
import ImageSerializationPlugin

#if canImport(Testing)
  // NB: We are importing only the implementation of Testing because that framework is not available
  //     in Xcode UI test targets.
  @_implementationOnly import Testing
#endif

/// Whether or not to change the default output image format to something else.
@available(
  *,
  deprecated,
  message:
    "Use 'withSnapshotTesting' to customize the image output format. See the documentation for more information."
)
public var imageFormat: ImageSerializationFormat {
  get {
    _imageFormat
  }
  set { _imageFormat = newValue }
}

@_spi(Internals)
public var _imageFormat: ImageSerializationFormat {
  get {
#if canImport(Testing)
    if let test = Test.current {
      for trait in test.traits.reversed() {
        if let diffTool = (trait as? _SnapshotsTestTrait)?.configuration.imageFormat {
          return diffTool
        }
      }
    }
#endif
    return __imageFormat
  }
  set {
    __imageFormat = newValue
  }
}

@_spi(Internals)
public var __imageFormat: ImageSerializationFormat = .defaultValue


/// Enhances failure messages with a command line diff tool expression that can be copied and pasted
/// into a terminal.
@available(
  *,
  deprecated,
  message:
    "Use 'withSnapshotTesting' to customize the diff tool. See the documentation for more information."
)
public var diffTool: SnapshotTestingConfiguration.DiffTool {
  get {
    _diffTool
  }
  set { _diffTool = newValue }
}

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

@_spi(Internals)
public var __diffTool: SnapshotTestingConfiguration.DiffTool = .default

/// Whether or not to record all new references.
@available(
  *, deprecated,
  message:
    "Use 'withSnapshotTesting' to customize the record mode. See the documentation for more information."
)
public var isRecording: Bool {
  get { SnapshotTestingConfiguration.current?.record ?? _record == .all }
  set { _record = newValue ? .all : .missing }
}

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
  CleanCounterBetweenTestCases.registerIfNeeded()

  let record =
    (recording == true ? .all : recording == false ? .missing : nil)
    ?? SnapshotTestingConfiguration.current?.record
    ?? _record
  return withSnapshotTesting(record: record) { () -> String? in
    do {
      let fileUrl = URL(fileURLWithPath: "\(filePath)", isDirectory: false)
      let fileName = fileUrl.deletingPathExtension().lastPathComponent

      let snapshotDirectoryUrl =
        snapshotDirectory.map { URL(fileURLWithPath: $0, isDirectory: true) }
        ?? fileUrl
        .deletingLastPathComponent()
        .appendingPathComponent("__Snapshots__")
        .appendingPathComponent(fileName)

      let identifier: String
      if let name = name {
        identifier = sanitizePathComponent(name)
      } else {
        let counter = counterQueue.sync { () -> Int in
          let key = snapshotDirectoryUrl.appendingPathComponent(testName)
          counterMap[key, default: 0] += 1
          return counterMap[key]!
        }
        identifier = String(counter)
      }

      let testName = sanitizePathComponent(testName)
      let snapshotFileUrl =
        snapshotDirectoryUrl
        .appendingPathComponent("\(testName).\(identifier)")
        .appendingPathExtension(snapshotting.pathExtension ?? "")
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

      func recordSnapshot() throws {
        try snapshotting.diffing.toData(diffable).write(to: snapshotFileUrl)
        #if !os(Linux) && !os(Windows)
          if !isSwiftTesting,
            ProcessInfo.processInfo.environment.keys.contains("__XCODE_BUILT_PRODUCTS_DIR_PATHS")
          {
            XCTContext.runActivity(named: "Attached Recorded Snapshot") { activity in
              let attachment = XCTAttachment(contentsOfFile: snapshotFileUrl)
              activity.add(attachment)
            }
          }
        #endif
      }

      guard
        record != .all,
        (record != .missing && record != .failed)
          || fileManager.fileExists(atPath: snapshotFileUrl.path)
      else {
        try recordSnapshot()

        return SnapshotTestingConfiguration.current?.record == .all
          ? """
          Record mode is on. Automatically recorded snapshot: …

          open "\(snapshotFileUrl.absoluteString)"

          Turn record mode off and re-run "\(testName)" to assert against the newly-recorded snapshot
          """
          : """
          No reference was found on disk. Automatically recorded snapshot: …

          open "\(snapshotFileUrl.absoluteString)"

          Re-run "\(testName)" to assert against the newly-recorded snapshot.
          """
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
        #if !os(Linux) && !os(Windows)
          if ProcessInfo.processInfo.environment.keys.contains("__XCODE_BUILT_PRODUCTS_DIR_PATHS") {
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
        try recordSnapshot()
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

private let counterQueue = DispatchQueue(label: "co.pointfree.SnapshotTesting.counter")
private var counterMap: [URL: Int] = [:]

func sanitizePathComponent(_ string: String) -> String {
  return
    string
    .replacingOccurrences(of: "\\W+", with: "-", options: .regularExpression)
    .replacingOccurrences(of: "^-|-$", with: "", options: .regularExpression)
}

// We need to clean counter between tests executions in order to support test-iterations.
private class CleanCounterBetweenTestCases: NSObject, XCTestObservation {
  private static var registered = false

  static func registerIfNeeded() {
    if Thread.isMainThread {
      doRegisterIfNeeded()
    } else {
      DispatchQueue.main.sync {
        doRegisterIfNeeded()
      }
    }
  }

  private static func doRegisterIfNeeded() {
    if !registered {
      registered = true
      XCTestObservationCenter.shared.addTestObserver(CleanCounterBetweenTestCases())
    }
  }

  func testCaseDidFinish(_ testCase: XCTestCase) {
    counterQueue.sync {
      counterMap = [:]
    }
  }
}
