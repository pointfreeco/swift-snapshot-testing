import Foundation
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import XCTest

public func assertInlineSnapshot<Value>(
  of value: @autoclosure () throws -> Value,
  as snapshotting: Snapshotting<Value, String>,
  timeout: TimeInterval = 5,
  file: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column,
  matches expected: (() -> String)? = nil
) {
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
    case .incorrectOrder, .interrupted, .invertedFulfillment, .timedOut:
      XCTFail()
      return
    @unknown default:
      XCTFail()
      return
    }
    guard !isRecording, let expected = expected?()
    else {
      inlineSnapshotState[File(path: file), default: []].append(
        InlineSnapshot(
          expected: expected?(),
          actual: actual,
          function: "\(function)",
          line: line,
          column: column
        )
      )
      return
    }
    if let difference = Diffing.lines.diff(actual, expected)?.0 {
      XCTFail(
        """
        Snapshot did not match. Difference: …

        \(difference.indenting(by: 2))
        """,
        file: file,
        line: line
      )
    }
  } catch {
    XCTFail("TODO: Show error message")
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
  var function: String
  var line: UInt
  var column: UInt
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
    let sourceLocationConverter = SourceLocationConverter(file: filePath, source: source)
    let snapshotRewriter = SnapshotRewriter(
      file: file,
      snapshots: snapshots.sorted(by: { $0.line < $1.line }),
      sourceLocationConverter: sourceLocationConverter
    )
    let updatedSource = snapshotRewriter.visit(sourceFile).description
    do {
      try updatedSource.write(toFile: filePath, atomically: true, encoding: .utf8)
      snapshotRewriter.report()
    } catch {
      XCTFail()
    }
  }
}

private class SnapshotRewriter: SyntaxRewriter {
  let file: File
  let indent: String
  let line: UInt?
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
      // functionCallExpr.calledExpression.as(IdentifierExprSyntax.self)?.identifier.text
      //   == "assertInlineSnapshot",
      (functionCallExpr.position..<functionCallExpr.endPosition).contains(
        self.sourceLocationConverter.position(
          ofLine: Int(snapshot.line), column: Int(snapshot.column)
        )
      )
    else {
      return ExprSyntax(functionCallExpr)
    }
    self.snapshots.removeFirst()
    var argumentList = functionCallExpr.argumentList
    if let index = argumentList.firstIndex(where: { $0.label?.text == "matches" }) {
      argumentList = argumentList.removing(
        childAt: argumentList.distance(from: argumentList.startIndex, to: index)
      )
      argumentList = argumentList.replacing(
        childAt: argumentList.count - 1,
        with: argumentList[argumentList.index(before: argumentList.endIndex)]
          .with(\.trailingComma, nil)
      )
    }
    let leadingTrivia = String(
      functionCallExpr.leadingTrivia.description.split(separator: "\n").last ?? ""
    )
    let delimiter = String(
      repeating: "#", count: snapshot.actual.hashCount(isMultiline: true)
    )
    let leadingIndent = leadingTrivia + self.indent
    let updatedFunctionCallExpr =
      functionCallExpr
      .with(\.argumentList, argumentList)
      .with(
        \.rightParen,
        (functionCallExpr.rightParen ?? .rightParenToken()).with(\.trailingTrivia, .space)
      )
      .with(
        \.trailingClosure,
        ClosureExprSyntax(
          leftBrace: .leftBraceToken(trailingTrivia: .newline),
          statements: CodeBlockItemListSyntax {
            StringLiteralExprSyntax(
              leadingTrivia: .init(stringLiteral: leadingIndent),
              openDelimiter: .rawStringDelimiter(delimiter),
              openQuote: .multilineStringQuoteToken(trailingTrivia: .newline),
              segments: [
                .stringSegment(
                  StringSegmentSyntax(
                    content: .stringSegment(snapshot.actual.indenting(with: leadingIndent))
                  )
                )
              ],
              closeQuote: .multilineStringQuoteToken(
                leadingTrivia: .newline + .init(stringLiteral: leadingIndent)
              ),
              closeDelimiter: .rawStringDelimiter(delimiter)
            )
          },
          rightBrace: .rightBraceToken(
            leadingTrivia: .newline + .init(stringLiteral: leadingTrivia)
          )
        ))
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
        """
        Record mode is on. Turn record mode off and run tests again to assert against recorded \
        snapshots.
        """,
        file: self.file.path,
        line: self.line ?? 1
      )
      return
    }
    for (snapshot, line) in self.newRecordings {
      var failure = "Automatically recorded a new snapshot."
      if let expected = snapshot.expected,
        let difference = Diffing.lines.diff(expected, snapshot.actual)?.0
      {
        failure += " Difference: …\n\n\(difference.indenting(by: 2))"
      }
      XCTFail(
        """
        \(failure)

        Re-run "\(snapshot.function)" to test against the newly-recorded value.
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
    var hashCount = 0
    let pattern = "(\(quote)[#]*)"
    while let range = substring.range(of: pattern, options: .regularExpression) {
      let count = substring.distance(from: range.lowerBound, to: range.upperBound) - offset
      hashCount = max(count, hashCount)
      substring = substring[range.upperBound...]
    }
    return hashCount
  }
}
