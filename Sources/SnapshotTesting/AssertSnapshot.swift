import XCTest

/// Enhances failure messages with a command line diff tool expression that can be copied and pasted into a terminal.
///
///     diffTool = "ksdiff"
public var diffTool: String? = nil

/// Whether or not to record all new references.
public var record = false

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
    matching: try value(),
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

  try? strategies.forEach { name, strategy in
    assertSnapshot(
      matching: try value(),
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

  try? strategies.forEach { strategy in
    assertSnapshot(
      matching: try value(),
      as: strategy,
      record: recording,
      timeout: timeout,
      file: file,
      testName: testName,
      line: line
    )
  }
}

/// Asserts that a given value matches a string literal.
///
/// Note: Empty `expectedValue` will be replaced automatically with generated output.
///
/// Usage:
/// ```
/// assertInlineSnapshot(of: value, as: .dump, toMatch: """
/// """)
/// ```
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - snapshotting: A strategy for serializing, deserializing, and comparing values.
///   - timeout: The amount of time a snapshot must be generated in.
///   - expectedValue: The expected output of snapshotting.
///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
public func assertInlineSnapshot<Value>(
  of value: @autoclosure () throws -> Value,
  as snapshotting: Snapshotting<Value, String>,
  timeout: TimeInterval = 5,
  toMatch expectedValue: String,
  file: StaticString = #file,
  line: UInt = #line
  ) {

  let failure = verifyInlineSnapshot(
    of: try value(),
    as: snapshotting,
    timeout: timeout,
    toMatch: expectedValue,
    file: file,
    line: line
  )
  guard let message = failure else { return }
  XCTFail(message, file: file, line: line)
}

/// Verifies that a given value matches a reference on disk.
///
/// Third party snapshot assert helpers can be built on top of this function. Simply invoke `verifySnapshot` with your own arguments, and then invoke `XCTFail` with the string returned if it is non-`nil`. For example, if you want the snapshot directory to be determined by an environment variable, you can create your own assert helper like so:
///
///     public func myAssertSnapshot<Value, Format>(
///       matching value: @autoclosure () throws -> Value,
///       as snapshotting: Snapshotting<Value, Format>,
///       named name: String? = nil,
///       record recording: Bool = false,
///       timeout: TimeInterval = 5,
///       file: StaticString = #file,
///       testName: String = #function,
///       line: UInt = #line
///       ) {
///
///         let snapshotDirectory = ProcessInfo.processInfo.environment["SNAPSHOT_REFERENCE_DIR"]! + "/" + #file
///         let failure = verifySnapshot(
///           matching: value,
///           as: snapshotting,
///           named: name,
///           record: recording,
///           snapshotDirectory: snapshotDirectory,
///           timeout: timeout,
///           file: file,
///           testName: testName
///         )
///         guard let message = failure else { return }
///         XCTFail(message, file: file, line: line)
///     }
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - snapshotting: A strategy for serializing, deserializing, and comparing values.
///   - name: An optional description of the snapshot.
///   - recording: Whether or not to record a new reference.
///   - snapshotDirectory: Optional directory to save snapshots. By default snapshots will be saved in a directory with the same name as the test file, and that directory will sit inside a directory `__Snapshots__` that sits next to your test file.
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

    let recording = recording || record

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
        let counter = counterQueue.sync { () -> Int in
          let key = snapshotDirectoryUrl.appendingPathComponent(testName)
          counterMap[key, default: 0] += 1
          return counterMap[key]!
        }
        identifier = String(counter)
      }

      let testName = sanitizePathComponent(testName)
      let snapshotFileUrl = snapshotDirectoryUrl
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
        return "Exceeded timeout of \(timeout) seconds waiting for snapshot"
      case .incorrectOrder, .invertedFulfillment, .interrupted:
        return "Couldn't snapshot value"
      @unknown default:
        return "Couldn't snapshot value"
      }

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
        if ProcessInfo.processInfo.environment.keys.contains("__XCODE_BUILT_PRODUCTS_DIR_PATHS") {
          XCTContext.runActivity(named: "Attached Failure Diff") { activity in
            attachments.forEach {
              activity.add($0)
            }
          }
        }
        #endif
      }

      let diffMessage = diffTool
        .map { "\($0) \"\(snapshotFileUrl.path)\" \"\(failedSnapshotFileUrl.path)\"" }
        ?? "@\(minus)\n\"\(snapshotFileUrl.path)\"\n@\(plus)\n\"\(failedSnapshotFileUrl.path)\""
      return """
      Snapshot does not match reference.

      \(diffMessage)

      \(failure.trimmingCharacters(in: .whitespacesAndNewlines))
      """
    } catch {
      return error.localizedDescription
    }
}

/// Verifies that a given value matches a string literal.
///
/// Third party snapshot assert helpers can be built on top of this function. Simply invoke `verifyInlineSnapshot` with your own arguments, and then invoke `XCTFail` with the string returned if it is non-`nil`.
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - snapshotting: A strategy for serializing, deserializing, and comparing values.
///   - timeout: The amount of time a snapshot must be generated in.
///   - expectedValue: The expected output of snapshotting.
///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
///   - testName: The name of the test in which failure occurred. Defaults to the function name of the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
/// - Returns: A failure message or, if the value matches, nil.
public func verifyInlineSnapshot<Value>(
  of value: @autoclosure () throws -> Value,
  as snapshotting: Snapshotting<Value, String>,
  timeout: TimeInterval = 5,
  toMatch expectedValue: String,
  file: StaticString = #file,
  line: UInt = #line
  )
  -> String? {

    do {
      let tookSnapshot = XCTestExpectation(description: "Took snapshot")
      var optionalDiffable: String?
      snapshotting.snapshot(try value()).run { b in
        optionalDiffable = b
        tookSnapshot.fulfill()
      }
      let result = XCTWaiter.wait(for: [tookSnapshot], timeout: timeout)
      switch result {
      case .completed:
        break
      case .timedOut:
        return "Exceeded timeout of \(timeout) seconds waiting for snapshot"
      case .incorrectOrder, .invertedFulfillment, .interrupted:
        return "Couldn't snapshot value"
      }

      let trimmingChars = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "\u{FEFF}"))
      guard let diffable = optionalDiffable?.trimmingCharacters(in: trimmingChars) else {
        return "Couldn't snapshot value"
      }

      let trimmedReference = expectedValue.trimmingCharacters(in: .whitespacesAndNewlines)

      /// Always perform diff, and return early on success!
      guard let (failure, attachments) = snapshotting.diffing.diff(trimmedReference, diffable) else {
        return nil
      }

      /// If that diff failed, we either record or fail.

      if record || trimmedReference.isEmpty {
        let fileName = "\(file)"
        let sourceCodeFilePath = URL(fileURLWithPath: fileName)
        var sourceCodeLines = try String(contentsOf: sourceCodeFilePath).split(separator: "\n", omittingEmptySubsequences: false)
        let lineIndex = Int(line)

        let otherRecordings = recordings[fileName, default: []]
        let otherRecordingsAboveThisLine = otherRecordings.filter { $0.line < lineIndex }
        let offsetStartIndex = otherRecordingsAboveThisLine.reduce(lineIndex) { $0 + $1.difference }
        let functionLineIndex = offsetStartIndex - 1
        var lineCountDifference = 0

        /// Convert `""` to multi-line literal
        if sourceCodeLines[functionLineIndex].hasSuffix(emptyStringLiteralWithCloseBrace) {
          /// eg.
          /// Converting:
          ///    assertInlineSnapshot(of: value, as: .dump, toMatch: "")
          /// to:
          ///    assertInlineSnapshot(of: value, as: .dump, toMatch: """
          ///    """)
          var functionCallLine = sourceCodeLines.remove(at: functionLineIndex)
          functionCallLine.removeLast(emptyStringLiteralWithCloseBrace.count)
          let indentText = indentation(of: functionCallLine)
          sourceCodeLines.insert(contentsOf: [
            functionCallLine + multiLineStringLiteralTerminator,
            indentText + multiLineStringLiteralTerminator + ")",
            ] as [String.SubSequence], at: functionLineIndex)
          lineCountDifference += 1
        }

        /// If they haven't got a multi-line literal by now, then just fail.
        guard sourceCodeLines[functionLineIndex].hasSuffix(multiLineStringLiteralTerminator) else {
          return "Please convert to a multi-line literal."
        }

        /// Find the end of multi-line literal and replace contents with recording.
        if let multiLineLiteralEndIndex = sourceCodeLines[offsetStartIndex...].firstIndex(where: { $0.contains(multiLineStringLiteralTerminator) }) {
          /// Convert actual value to Lines to insert
          let indentText = indentation(of: sourceCodeLines[multiLineLiteralEndIndex])
          let newDiffableLines = diffable
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { Substring(indentText + $0) }
          lineCountDifference += newDiffableLines.count - (multiLineLiteralEndIndex - offsetStartIndex)

          let fileRecording = FileRecording(line: lineIndex, difference: lineCountDifference)
          recordings[fileName, default: []].append(fileRecording)

          /// Insert the lines
          sourceCodeLines.replaceSubrange(offsetStartIndex ..< multiLineLiteralEndIndex, with: newDiffableLines)

          try sourceCodeLines
            .joined(separator: "\n")
            .data(using: String.Encoding.utf8)?
            .write(to: sourceCodeFilePath)

          if otherRecordings.isEmpty {
            /// If no other recording has been made, then fail!
            return "🆕 Test updated! Please re-run test."
          } else {
            /// There is already an failure in this file,
            /// and we don't want to write to the wrong place.
            return nil
          }
        }
      }

      /// Did not successfully record, so we will fail.
      if !attachments.isEmpty {
        #if !os(Linux)
        if ProcessInfo.processInfo.environment.keys.contains("__XCODE_BUILT_PRODUCTS_DIR_PATHS") {
          XCTContext.runActivity(named: "Attached Failure Diff") { activity in
            attachments.forEach {
              activity.add($0)
            }
          }
        }
        #endif
      }

      return """
      Snapshot does not match reference.

      \(failure.trimmingCharacters(in: .whitespacesAndNewlines))
      """

    } catch {
      return error.localizedDescription
    }
}

// MARK: - Private

private struct FileRecording {
    let line: Int
    let difference: Int
}

private let counterQueue = DispatchQueue(label: "co.pointfree.SnapshotTesting.counter")
private var counterMap: [URL: Int] = [:]
private var recordings: [String: [FileRecording]] = [:]
private let emptyStringLiteralWithCloseBrace = "\"\")"
private let multiLineStringLiteralTerminator = "\"\"\""

private func indentation<S: StringProtocol>(of str: S) -> String {
  var count = 0
  for char in str {
    guard char == " " else { break }
    count += 1
  }
  return String(repeating: " ", count: count)
}

private func sanitizePathComponent(_ string: String) -> String {
  return string
    .replacingOccurrences(of: "\\W+", with: "-", options: .regularExpression)
    .replacingOccurrences(of: "^-|-$", with: "", options: .regularExpression)
}
