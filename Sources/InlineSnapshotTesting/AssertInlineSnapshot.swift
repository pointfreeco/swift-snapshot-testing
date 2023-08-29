import Foundation
import SnapshotTesting
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import XCTest

public struct InlineSnapshotSyntaxDescriptor: Hashable {
  public var trailingClosureLabel: String
  public var trailingClosureOffset: Int

  public init(trailingClosureLabel: String = "matches", trailingClosureOffset: Int = 0) {
    self.trailingClosureLabel = trailingClosureLabel
    self.trailingClosureOffset = trailingClosureOffset
  }
}

public func assertInlineSnapshot<Value>(
  of value: @autoclosure () throws -> Value,
  as snapshotting: Snapshotting<Value, String>,
  message: @autoclosure () -> String = "",
  timeout: TimeInterval = 5,
  syntaxDescriptor: InlineSnapshotSyntaxDescriptor = .init(),
  matches expected: (() -> String)? = nil,
  file: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) {
  XCTAssertEqual(1, 1)
  XCTCurrentTestCase?.addTeardownBlock {
    writeInlineSnapshots()
  }
  do {
    var actual: String!
    let expectation = XCTestExpectation()
    try snapshotting.snapshot(value()).run {
      actual = $0
      expectation.fulfill()
    }
    switch XCTWaiter.wait(for: [expectation], timeout: timeout) {
    case .completed:
      break
    case .timedOut:
      XCTFail(
        """
        Exceeded timeout of \(timeout) seconds waiting for snapshot.

        This can happen when an asynchronously rendered view (like a web view) has not loaded. \
        Ensure that every subview of the view hierarchy has loaded to avoid timeouts, or, if a \
        timeout is unavoidable, consider setting the "timeout" parameter of "assertSnapshot" to \
        a higher value.
        """,
        file: file,
        line: line
      )
      return
    case .incorrectOrder, .interrupted, .invertedFulfillment:
      XCTFail("Couldn't snapshot value", file: file, line: line)
      return
    @unknown default:
      XCTFail("Couldn't snapshot value", file: file, line: line)
      return
    }
    guard !isRecording, let expected = expected?()
    else {
      inlineSnapshotState[File(path: file), default: []].append(
        InlineSnapshot(
          expected: expected?(),
          actual: actual,
          diffing: snapshotting.diffing,
          wasRecording: isRecording,
          syntaxDescriptor: syntaxDescriptor,
          function: "\(function)",
          line: line,
          column: column
        )
      )
      return
    }
    if let difference = snapshotting.diffing.diff(actual, expected)?.0 {
      let message = message()
      XCTFail(
        """
        \(message.isEmpty ? "Snapshot did not match. Difference: …" : message)

        \(difference.indenting(by: 2))
        """,
        file: file,
        line: line
      )
    }
  } catch {
    XCTFail("Threw error: \(error)", file: file, line: line)
  }
}

private struct File: Hashable {
  let path: StaticString
  static func == (lhs: Self, rhs: Self) -> Bool {
    "\(lhs.path)" == "\(rhs.path)"
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine("\(self.path)")
  }
}

private struct InlineSnapshot: Hashable {
  var expected: String?
  var actual: String
  var diffing: Diffing<String>
  var wasRecording: Bool
  var syntaxDescriptor: InlineSnapshotSyntaxDescriptor
  var function: String
  var line: UInt
  var column: UInt

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.expected == rhs.expected
      && lhs.actual == rhs.actual
      && lhs.wasRecording == rhs.wasRecording
      && lhs.syntaxDescriptor == rhs.syntaxDescriptor
      && lhs.function == rhs.function
      && lhs.line == rhs.line
      && lhs.column == rhs.column
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.expected)
    hasher.combine(self.actual)
    hasher.combine(self.wasRecording)
    hasher.combine(self.syntaxDescriptor)
    hasher.combine(self.function)
    hasher.combine(self.line)
    hasher.combine(self.column)
  }
}

private var XCTCurrentTestCase: XCTestCase? {
  guard
    let observers = XCTestObservationCenter.shared.perform(Selector(("observers")))?
      .takeUnretainedValue() as? [AnyObject],
    let observer =
      observers
      .first(where: { NSStringFromClass(type(of: $0)) == "XCTestMisuseObserver" }),
    let currentTestCase = observer.perform(Selector(("currentTestCase")))?
      .takeUnretainedValue() as? XCTestCase
  else { return nil }
  return currentTestCase
}

private var inlineSnapshotState: [File: [InlineSnapshot]] = [:]

private func writeInlineSnapshots() {
  defer { inlineSnapshotState.removeAll() }
  for (file, snapshots) in inlineSnapshotState {
    let filePath = "\(file.path)"
    guard let source = try? String(contentsOfFile: filePath)
    else {
      XCTFail("TODO: This shouldn't happen, but finesse failure message")
      return
    }
    let sourceFile = Parser.parse(source: source)
    let sourceLocationConverter = SourceLocationConverter(fileName: filePath, tree: sourceFile)
    let snapshotRewriter = SnapshotRewriter(
      file: file,
      snapshots: snapshots.sorted(by: { $0.line < $1.line }),
      sourceLocationConverter: sourceLocationConverter
    )
    let updatedSource = snapshotRewriter.visit(sourceFile).description
    do {
      if source != updatedSource {
        try updatedSource.write(toFile: filePath, atomically: true, encoding: .utf8)
      }
      snapshotRewriter.report()
    } catch {
      XCTFail("Threw error: \(error)")
    }
  }
}

private class SnapshotRewriter: SyntaxRewriter {
  let file: File
  let indent: String
  let line: UInt?
  let wasRecording: Bool
  var newRecordings: [(snapshot: InlineSnapshot, line: UInt)] = []
  var offset = 0
  var snapshots: [InlineSnapshot]
  let sourceLocationConverter: SourceLocationConverter

  init(
    file: File,
    snapshots: [InlineSnapshot],
    sourceLocationConverter: SourceLocationConverter
  ) {
    self.file = file
    self.line = snapshots.first?.line
    self.wasRecording = snapshots.first?.wasRecording ?? isRecording
    self.indent = String(
      sourceLocationConverter.sourceLines
        .first(where: { $0.first?.isWhitespace == true && $0 != "\n" })?
        .prefix(while: { $0.isWhitespace })
        ?? "    "
    )
    self.snapshots = snapshots
    self.sourceLocationConverter = sourceLocationConverter
  }

  override func visit(_ functionCallExpr: FunctionCallExprSyntax) -> ExprSyntax {
    guard
      let snapshot = snapshots.first,
      (functionCallExpr.position..<functionCallExpr.endPosition).contains(
        self.sourceLocationConverter.position(
          ofLine: Int(snapshot.line), column: Int(snapshot.column)
        )
      ),
      snapshot.expected != snapshot.actual
    else {
      return ExprSyntax(functionCallExpr)
    }
    self.snapshots.removeFirst()

    let leadingTrivia = String(
      functionCallExpr.leadingTrivia.description.split(separator: "\n").last ?? ""
    )
    let delimiter = String(
      repeating: "#", count: snapshot.actual.hashCount(isMultiline: true)
    )
    let leadingIndent = leadingTrivia + self.indent
    let snapshotClosure = ClosureExprSyntax(
      leftBrace: .leftBraceToken(trailingTrivia: .newline),
      statements: CodeBlockItemListSyntax {
        StringLiteralExprSyntax(
          leadingTrivia: .init(stringLiteral: leadingIndent),
          openingPounds: .rawStringPoundDelimiter(delimiter),
          openingQuote: .multilineStringQuoteToken(trailingTrivia: .newline),
          segments: [
            .stringSegment(
              StringSegmentSyntax(
                content: .stringSegment(snapshot.actual.indenting(with: leadingIndent))
              )
            )
          ],
          closingQuote: .multilineStringQuoteToken(
            leadingTrivia: .newline + .init(stringLiteral: leadingIndent)
          ),
          closingPounds: .rawStringPoundDelimiter(delimiter)
        )
      },
      rightBrace: .rightBraceToken(
        leadingTrivia: .newline + .init(stringLiteral: leadingTrivia)
      )
    )

    var arguments = functionCallExpr.arguments

    let firstTrailingClosureOffset = arguments
      .enumerated()
      .reversed()
      .prefix(while: { $0.element.expression.is(ClosureExprSyntax.self) })
      .last?
      .offset
      ?? arguments.count

    let trailingClosureOffset = firstTrailingClosureOffset
      + snapshot.syntaxDescriptor.trailingClosureOffset

    let updatedFunctionCallExpr: FunctionCallExprSyntax
    let centeredTrailingClosureOffset = trailingClosureOffset - arguments.count
    
    switch centeredTrailingClosureOffset {
    case ..<0:
      let index = arguments.index(arguments.startIndex, offsetBy: trailingClosureOffset)
      // TODO: Validate argument label and argument syntax?
      arguments[index].expression = ExprSyntax(snapshotClosure)
      updatedFunctionCallExpr = functionCallExpr.with(\.arguments, arguments)

    case 0:
      if snapshot.wasRecording || functionCallExpr.trailingClosure == nil {
        updatedFunctionCallExpr = functionCallExpr.with(
          \.trailingClosure,
          snapshotClosure.with(\.leadingTrivia, snapshotClosure.leadingTrivia + .space)
        )
      } else {
        fatalError("TODO")
      }

    case 1...:
      var additionalTrailingClosures = functionCallExpr.additionalTrailingClosures ?? []
      if
        !additionalTrailingClosures.isEmpty,
        let index = additionalTrailingClosures.index(
          additionalTrailingClosures.startIndex,
          offsetBy: centeredTrailingClosureOffset - 1,
          limitedBy: additionalTrailingClosures.endIndex
        )
      {
        if snapshot.wasRecording {
          additionalTrailingClosures[index].closure = snapshotClosure
        } else {
          return ExprSyntax(functionCallExpr)
        }
      } else if centeredTrailingClosureOffset == 1 {
        additionalTrailingClosures.append(
          MultipleTrailingClosureElementSyntax(
            leadingTrivia: .space,
            label: TokenSyntax(stringLiteral: snapshot.syntaxDescriptor.trailingClosureLabel),
            closure: snapshotClosure.with(\.leadingTrivia, snapshotClosure.leadingTrivia + .space)
          )
        )
      } else {
        fatalError("TODO")
      }
      updatedFunctionCallExpr = functionCallExpr
        .with(\.additionalTrailingClosures, additionalTrailingClosures)

    default:
      fatalError("TODO")
    }

    defer {
      let lineCount = functionCallExpr.description
        .split(separator: "\n", omittingEmptySubsequences: false)
        .count
      let updatedLineCount = updatedFunctionCallExpr.description
        .split(separator: "\n", omittingEmptySubsequences: false)
        .count
      self.offset += updatedLineCount - lineCount
    }
    if snapshot.expected != snapshot.actual {
      let line = UInt(
        functionCallExpr.calledExpression.startLocation(
          converter: self.sourceLocationConverter,
          afterLeadingTrivia: true
        )
        .line + self.offset
      )
      self.newRecordings.append((snapshot: snapshot, line: line))
    }
    return ExprSyntax(updatedFunctionCallExpr)
  }

  func report() {
    guard !self.newRecordings.isEmpty else {
      XCTFail(
        self.wasRecording
          ?
          """
          Record mode is on. Turn record mode off and run tests again to assert against recorded \
          snapshots.
          """
          :
          """
          Could not assert against inline snapshot. Please file an issue with the author of this \
          helper.
          """,
        file: self.file.path,
        line: self.line ?? 1
      )
      return
    }
    for (snapshot, line) in self.newRecordings {
      var failure = "Automatically recorded a new snapshot."
      if let expected = snapshot.expected,
         let difference = snapshot.diffing.diff(expected, snapshot.actual)?.0
      {
        failure += " Difference: …\n\n\(difference.indenting(by: 2))"
      }
      XCTFail(
        """
        \(failure)

        Re-run "\(snapshot.function)" to test against the newly-recorded snapshot.
        """,
        file: self.file.path,
        line: line
      )
    }
  }
}

extension String {
  fileprivate func indenting(by count: Int) -> String {
    self.indenting(with: String(repeating: " ", count: count))
  }

  fileprivate func indenting(with prefix: String) -> String {
    guard !prefix.isEmpty else { return self }
    return self.replacingOccurrences(
      of: #"([^\n]+)"#,
      with: "\(prefix)$1",
      options: .regularExpression
    )
  }

  fileprivate func hashCount(isMultiline: Bool) -> Int {
    let (quote, offset) = isMultiline ? ("\"\"\"", 2) : ("\"", 0)
    var substring = self[...]
    var hashCount = self.contains(#"\"#) ? 1 : 0
    let pattern = "(\(quote)[#]*)"
    while let range = substring.range(of: pattern, options: .regularExpression) {
      let count = substring.distance(from: range.lowerBound, to: range.upperBound) - offset
      hashCount = max(count, hashCount)
      substring = substring[range.upperBound...]
    }
    return hashCount
  }
}
