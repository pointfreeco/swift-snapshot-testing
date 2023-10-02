import Foundation
import XCTest

// Deprecated after 1.12.0:

@available(
  *,
  deprecated,
  message: """Use 'assertInlineSnapshot(of:)' from the 'InlineSnapshotTesting' module, instead."""
)
public func _assertInlineSnapshot<Value>(
  matching value: @autoclosure () throws -> Value,
  as snapshotting: Snapshotting<Value, String>,
  record recording: Bool = false,
  timeout: TimeInterval = 5,
  with reference: String,
  file: StaticString = #file,
  testName: String = #function,
  line: UInt = #line
) {

  let failure = _verifyInlineSnapshot(
    matching: try value(),
    as: snapshotting,
    record: recording,
    timeout: timeout,
    with: reference,
    file: file,
    testName: testName,
    line: line
  )
  guard let message = failure else { return }
  XCTFail(message, file: file, line: line)
}

@available(
  *,
  deprecated,
  message: """Use 'assertInlineSnapshot(of:)' from the 'InlineSnapshotTesting' module, instead."""
)
public func _verifyInlineSnapshot<Value>(
  matching value: @autoclosure () throws -> Value,
  as snapshotting: Snapshotting<Value, String>,
  record recording: Bool = false,
  timeout: TimeInterval = 5,
  with reference: String,
  file: StaticString = #file,
  testName: String = #function,
  line: UInt = #line
)
  -> String?
{

  let recording = recording || isRecording

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

    let trimmingChars = CharacterSet.whitespacesAndNewlines.union(
      CharacterSet(charactersIn: "\u{FEFF}"))
    guard let diffable = optionalDiffable?.trimmingCharacters(in: trimmingChars) else {
      return "Couldn't snapshot value"
    }

    let trimmedReference = reference.trimmingCharacters(in: .whitespacesAndNewlines)

    // Always perform diff, and return early on success!
    guard let (failure, attachments) = snapshotting.diffing.diff(trimmedReference, diffable) else {
      return nil
    }

    // If that diff failed, we either record or fail.
    if recording || trimmedReference.isEmpty {
      let fileName = "\(file)"
      let sourceCodeFilePath = URL(fileURLWithPath: fileName, isDirectory: false)
      let sourceCode = try String(contentsOf: sourceCodeFilePath)
      var newRecordings = recordings

      let modifiedSource = try writeInlineSnapshot(
        &newRecordings,
        Context(
          sourceCode: sourceCode,
          diffable: diffable,
          fileName: fileName,
          lineIndex: Int(line)
        )
      ).sourceCode

      try modifiedSource
        .data(using: String.Encoding.utf8)?
        .write(to: sourceCodeFilePath)

      if newRecordings != recordings {
        recordings = newRecordings
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

    /// Did not successfully record, so we will fail.
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

    return """
      Snapshot does not match reference.

      \(failure.trimmingCharacters(in: .whitespacesAndNewlines))
      """

  } catch {
    return error.localizedDescription
  }
}

private typealias Recordings = [String: [FileRecording]]

private struct Context {
  let sourceCode: String
  let diffable: String
  let fileName: String
  // First line of a file is line 1 (as with the #line macro)
  let lineIndex: Int

  func setSourceCode(_ newSourceCode: String) -> Context {
    return Context(
      sourceCode: newSourceCode,
      diffable: diffable,
      fileName: fileName,
      lineIndex: lineIndex
    )
  }
}

private func writeInlineSnapshot(
  _ recordings: inout Recordings,
  _ context: Context
) throws -> Context {
  var sourceCodeLines = context.sourceCode
    .split(separator: "\n", omittingEmptySubsequences: false)

  let otherRecordings = recordings[context.fileName, default: []]
  let otherRecordingsAboveThisLine = otherRecordings.filter { $0.line < context.lineIndex }
  let offsetStartIndex = otherRecordingsAboveThisLine.reduce(context.lineIndex) {
    $0 + $1.difference
  }
  let functionLineIndex = offsetStartIndex - 1
  var lineCountDifference = 0

  // Convert `""` to multi-line literal
  if sourceCodeLines[functionLineIndex].hasSuffix(emptyStringLiteralWithCloseBrace) {
    // Convert:
    //    _assertInlineSnapshot(matching: value, as: .dump, with: "")
    // to:
    //    _assertInlineSnapshot(matching: value, as: .dump, with: """
    //    """)
    var functionCallLine = sourceCodeLines.remove(at: functionLineIndex)
    functionCallLine.removeLast(emptyStringLiteralWithCloseBrace.count)
    let indentText = indentation(of: functionCallLine)
    sourceCodeLines.insert(
      contentsOf: [
        functionCallLine + multiLineStringLiteralTerminator,
        indentText + multiLineStringLiteralTerminator + ")",
      ] as [String.SubSequence], at: functionLineIndex)
    lineCountDifference += 1
  }

  /// If they haven't got a multi-line literal by now, then just fail.
  guard sourceCodeLines[functionLineIndex].hasSuffix(multiLineStringLiteralTerminator) else {
    struct InlineError: LocalizedError {
      var errorDescription: String? {
        return """
          To use inline snapshots, please convert the "with" argument to a multi-line literal.
          """
      }
    }
    throw InlineError()
  }

  /// Find the end of multi-line literal and replace contents with recording.
  if let multiLineLiteralEndIndex = sourceCodeLines[offsetStartIndex...].firstIndex(where: {
    $0.hasClosingMultilineStringDelimiter()
  }) {

    let diffableLines = context.diffable.split(separator: "\n")

    // Add #'s to the multiline string literal if needed
    let numberSigns: String
    if context.diffable.hasEscapedSpecialCharactersLiteral() {
      numberSigns = String(repeating: "#", count: context.diffable.numberOfNumberSignsNeeded())
    } else if nil != diffableLines.first(where: { $0.endsInBackslash() }) {
      // We want to avoid \ being interpreted as an escaped newline in the recorded inline snapshot
      numberSigns = "#"
    } else {
      numberSigns = ""
    }
    let multiLineStringLiteralTerminatorPre = numberSigns + multiLineStringLiteralTerminator
    let multiLineStringLiteralTerminatorPost = multiLineStringLiteralTerminator + numberSigns

    // Update opening (#...)"""
    sourceCodeLines[functionLineIndex].replaceFirstOccurrence(
      of: extendedOpeningStringDelimitersPattern,
      with: multiLineStringLiteralTerminatorPre
    )

    // Update closing """(#...)
    sourceCodeLines[multiLineLiteralEndIndex].replaceFirstOccurrence(
      of: extendedClosingStringDelimitersPattern,
      with: multiLineStringLiteralTerminatorPost
    )

    /// Convert actual value to Lines to insert
    let indentText = indentation(of: sourceCodeLines[multiLineLiteralEndIndex])
    let newDiffableLines = context.diffable
      .split(separator: "\n", omittingEmptySubsequences: false)
      .map { Substring(indentText + $0) }
    lineCountDifference += newDiffableLines.count - (multiLineLiteralEndIndex - offsetStartIndex)

    let fileRecording = FileRecording(line: context.lineIndex, difference: lineCountDifference)

    /// Insert the lines
    sourceCodeLines.replaceSubrange(
      offsetStartIndex..<multiLineLiteralEndIndex, with: newDiffableLines)

    recordings[context.fileName, default: []].append(fileRecording)
    return context.setSourceCode(sourceCodeLines.joined(separator: "\n"))
  }

  return context.setSourceCode(sourceCodeLines.joined(separator: "\n"))
}

private struct FileRecording: Equatable {
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

extension Substring {
  fileprivate mutating func replaceFirstOccurrence(of pattern: String, with newString: String) {
    let newString = replacingOccurrences(of: pattern, with: newString, options: .regularExpression)
    self = Substring(newString)
  }

  fileprivate func hasOpeningMultilineStringDelimiter() -> Bool {
    return range(of: extendedOpeningStringDelimitersPattern, options: .regularExpression) != nil
  }

  fileprivate func hasClosingMultilineStringDelimiter() -> Bool {
    return range(of: extendedClosingStringDelimitersPattern, options: .regularExpression) != nil
  }

  fileprivate func endsInBackslash() -> Bool {
    if let lastChar = last {
      return lastChar == Character(#"\"#)
    }
    return false
  }
}

private let emptyStringLiteralWithCloseBrace = "\"\")"
private let multiLineStringLiteralTerminator = "\"\"\""
private let extendedOpeningStringDelimitersPattern = #"#{0,}\"\"\""#
private let extendedClosingStringDelimitersPattern = ##"\"\"\"#{0,}"##

// When we modify a file, the line numbers reported by the compiler through #line are no longer
// accurate. With the FileRecording values we keep track of we modify the files so we can adjust
// line numbers.
private var recordings: Recordings = [:]

// Deprecated after 1.11.1:

@available(iOS, deprecated: 10000, message: "Use `assertSnapshot(of:…:)` instead.")
@available(macOS, deprecated: 10000, message: "Use `assertSnapshot(of:…:)` instead.")
@available(tvOS, deprecated: 10000, message: "Use `assertSnapshot(of:…:)` instead.")
@available(watchOS, deprecated: 10000, message: "Use `assertSnapshot(of:…:)` instead.")
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
  assertSnapshot(
    of: try value(),
    as: snapshotting,
    named: name,
    record: recording,
    timeout: timeout,
    file: file,
    testName: testName,
    line: line
  )
}

@available(iOS, deprecated: 10000, message: "Use `assertSnapshots(of:…:)` instead.")
@available(macOS, deprecated: 10000, message: "Use `assertSnapshots(of:…:)` instead.")
@available(tvOS, deprecated: 10000, message: "Use `assertSnapshots(of:…:)` instead.")
@available(watchOS, deprecated: 10000, message: "Use `assertSnapshots(of:…:)` instead.")
public func assertSnapshots<Value, Format>(
  matching value: @autoclosure () throws -> Value,
  as strategies: [String: Snapshotting<Value, Format>],
  record recording: Bool = false,
  timeout: TimeInterval = 5,
  file: StaticString = #file,
  testName: String = #function,
  line: UInt = #line
) {
  assertSnapshots(
    of: try value(),
    as: strategies,
    record: recording,
    timeout: timeout,
    file: file,
    testName: testName,
    line: line
  )
}

@available(iOS, deprecated: 10000, message: "Use `assertSnapshots(of:…:)` instead.")
@available(macOS, deprecated: 10000, message: "Use `assertSnapshots(of:…:)` instead.")
@available(tvOS, deprecated: 10000, message: "Use `assertSnapshots(of:…:)` instead.")
@available(watchOS, deprecated: 10000, message: "Use `assertSnapshots(of:…:)` instead.")
public func assertSnapshots<Value, Format>(
  matching value: @autoclosure () throws -> Value,
  as strategies: [Snapshotting<Value, Format>],
  record recording: Bool = false,
  timeout: TimeInterval = 5,
  file: StaticString = #file,
  testName: String = #function,
  line: UInt = #line
) {
  assertSnapshots(
    of: try value(),
    as: strategies,
    record: recording,
    timeout: timeout,
    file: file,
    testName: testName,
    line: line
  )
}

@available(iOS, deprecated: 10000, message: "Use `verifySnapshot(of:…:)` instead.")
@available(macOS, deprecated: 10000, message: "Use `verifySnapshot(of:…:)` instead.")
@available(tvOS, deprecated: 10000, message: "Use `verifySnapshot(of:…:)` instead.")
@available(watchOS, deprecated: 10000, message: "Use `verifySnapshot(of:…:)` instead.")
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
) -> String? {
  verifySnapshot(
    of: try value(),
    as: snapshotting,
    named: name,
    record: recording,
    snapshotDirectory: snapshotDirectory,
    timeout: timeout,
    file: file,
    testName: testName,
    line: line
  )
}

@available(*, deprecated, renamed: "XCTestCase")
public typealias SnapshotTestCase = XCTestCase
