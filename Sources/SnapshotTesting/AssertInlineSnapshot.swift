import XCTest

/// Asserts that a given value matches a string literal.
///
/// Note: Empty `reference` will be replaced automatically with generated output.
///
/// Usage:
/// ```
/// _assertInlineSnapshot(matching: value, as: .dump, with: """
/// """)
/// ```
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - snapshotting: A strategy for serializing, deserializing, and comparing values.
///   - timeout: The amount of time a snapshot must be generated in.
///   - reference: The expected output of snapshotting.
///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
public func _assertInlineSnapshot<Value>(
  matching value: @autoclosure () throws -> Value,
  as snapshotting: Snapshotting<Value, String>,
  timeout: TimeInterval = 5,
  with reference: String,
  file: StaticString = #file,
  testName: String = #function,
  line: UInt = #line
  ) {

  let failure = _verifyInlineSnapshot(
    matching: try value(),
    as: snapshotting,
    timeout: timeout,
    with: reference,
    file: file,
    testName: testName,
    line: line
  )
  guard let message = failure else { return }
  XCTFail(message, file: file, line: line)
}

/// Verifies that a given value matches a string literal.
///
/// Third party snapshot assert helpers can be built on top of this function. Simply invoke `verifyInlineSnapshot` with your own arguments, and then invoke `XCTFail` with the string returned if it is non-`nil`.
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - snapshotting: A strategy for serializing, deserializing, and comparing values.
///   - timeout: The amount of time a snapshot must be generated in.
///   - reference: The expected output of snapshotting.
///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
///   - testName: The name of the test in which failure occurred. Defaults to the function name of the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
/// - Returns: A failure message or, if the value matches, nil.
public func _verifyInlineSnapshot<Value>(
  matching value: @autoclosure () throws -> Value,
  as snapshotting: Snapshotting<Value, String>,
  timeout: TimeInterval = 5,
  with reference: String,
  file: StaticString = #file,
  testName: String = #function,
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
      @unknown default:
        return "Couldn't snapshot value"
      }

      let trimmingChars = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "\u{FEFF}"))
      guard let diffable = optionalDiffable?.trimmingCharacters(in: trimmingChars) else {
        return "Couldn't snapshot value"
      }

      let trimmedReference = reference.trimmingCharacters(in: .whitespacesAndNewlines)

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
          ///    _assertInlineSnapshot(matching: value, as: .dump, with: "")
          /// to:
          ///    _assertInlineSnapshot(matching: value, as: .dump, with: """
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
          return "To use inline snapshots, please convert `with` argument to a multi-line literal."
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
            return """
            No reference was found inline. Automatically recorded snapshot.

            Re-run "\(sanitizePathComponent(testName))" to test against the newly-recorded snapshot.
            """
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

private struct FileRecording {
  let line: Int
  let difference: Int
}

private func indentation<S: StringProtocol>(of str: S) -> String {
  var count = 0
  for char in str {
    guard char == " " else { break }
    count += 1
  }
  return String(repeating: " ", count: count)
}

private let emptyStringLiteralWithCloseBrace = "\"\")"
private var recordings: [String: [FileRecording]] = [:]
private let multiLineStringLiteralTerminator = "\"\"\""
