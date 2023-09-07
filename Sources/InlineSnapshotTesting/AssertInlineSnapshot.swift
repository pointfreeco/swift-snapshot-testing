import Foundation
import SnapshotTesting
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import XCTest

/// Asserts that a given value matches an inline string snapshot.
///
/// See <doc:InlineSnapshotTesting> for more info.
///
/// - Parameters:
///   - value: A value to compare against a snapshot.
///   - snapshotting: A strategy for snapshotting and comparing values.
///   - message: An optional description of the assertion, for inclusion in test results.
///   - timeout: The amount of time a snapshot must be generated in.
///   - syntaxDescriptor: An optional description of where the snapshot is inlined. This parameter
///     should be omitted unless you are writing a custom helper that calls this function under the
///     hood. See ``InlineSnapshotSyntaxDescriptor`` for more.
///   - expected: An optional closure that returns a previously generated snapshot. When omitted,
///     the library will automatically write a snapshot into your test file at the call sight of the
///     assertion.
///   - file: The file where the assertion occurs. The default is the filename of the test case
///     where you call this function.
///   - function: The function where the assertion occurs. The default is the name of the test
///     method where you call this function.
///   - line: The line where the assertion occurs. The default is the line number where you call
///     this function.
///   - column: The column where the assertion occurs. The default is the line number where you call
///     this function.
public func assertInlineSnapshot<Value>(
  of value: @autoclosure () throws -> Value,
  as snapshotting: Snapshotting<Value, String>,
  message: @autoclosure () -> String = "",
  timeout: TimeInterval = 5,
  syntaxDescriptor: InlineSnapshotSyntaxDescriptor = InlineSnapshotSyntaxDescriptor(),
  matches expected: (() -> String)? = nil,
  file: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) {
  defer {
    if let XCTCurrentTestCase = XCTCurrentTestCase {
      XCTCurrentTestCase.addTeardownBlock {
        writeInlineSnapshots()
      }
    } else {
      writeInlineSnapshots()
    }
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

        This can happen when an asynchronously loaded value (like a network response) has not \
        loaded. If a timeout is unavoidable, consider setting the "timeout" parameter of
        "assertInlineSnapshot" to a higher value.
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
      let filePath = "\(file)"
      var trailingClosureLine: Int?
      if let source = try? String(contentsOfFile: filePath) {
        let sourceFile = Parser.parse(source: source)
        let sourceLocationConverter = SourceLocationConverter(fileName: filePath, tree: sourceFile)
        let visitor = SnapshotVisitor(
          functionCallLine: Int(line),
          functionCallColumn: Int(column),
          sourceLocationConverter: sourceLocationConverter,
          syntaxDescriptor: syntaxDescriptor
        )
        visitor.walk(sourceFile)
        trailingClosureLine = visitor.trailingClosureLine
      }
      let message = message()
      XCTFail(
        """
        \(message.isEmpty ? "Snapshot did not match. Difference: …" : message)

        \(difference.indenting(by: 2))
        """,
        file: file,
        line: trailingClosureLine.map(UInt.init) ?? line
      )
    }
  } catch {
    XCTFail("Threw error: \(error)", file: file, line: line)
  }
}

/// A structure that describes the location of an inline snapshot.
///
/// Provide this structure when defining custom snapshot functions that call
/// ``assertInlineSnapshot(of:as:message:timeout:syntaxDescriptor:matches:file:function:line:column:)``
/// under the hood.
public struct InlineSnapshotSyntaxDescriptor: Hashable {
  /// The label of the trailing closure that returns the inline snapshot.
  public var trailingClosureLabel: String

  /// The offset of the trailing closure that returns the inline snapshot, relative to the first
  /// trailing closure.
  ///
  /// For example, a helper function with a few parameters and a single trailing closure has a
  /// trailing closure offset of 0:
  ///
  /// ```swift
  /// customInlineSnapshot(of: value, "Should match") {
  ///   // Inline snapshot...
  /// }
  /// ```
  ///
  /// While a helper function with a trailing closure preceding the snapshot closure has an offset
  /// of 1:
  ///
  /// ```swift
  /// customInlineSnapshot("Should match") {
  ///   // Some other parameter...
  /// } matches: {
  ///   // Inline snapshot...
  /// }
  /// ```
  public var trailingClosureOffset: Int

  /// Initializes an inline snapshot syntax descriptor.
  ///
  /// - Parameters:
  ///   - trailingClosureLabel: The label of the trailing closure that returns the inline snapshot.
  ///   - trailingClosureOffset: The offset of the trailing closure that returns the inline
  ///     snapshot, relative to the first trailing closure.
  public init(trailingClosureLabel: String = "matches", trailingClosureOffset: Int = 0) {
    self.trailingClosureLabel = trailingClosureLabel
    self.trailingClosureOffset = trailingClosureOffset
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
    let line = snapshots.first?.line ?? 1
    guard let source = try? String(contentsOfFile: filePath)
    else {
      XCTFail("Couldn't load snapshot from disk", file: file.path, line: line)
      return
    }
    let sourceFile = Parser.parse(source: source)
    let sourceLocationConverter = SourceLocationConverter(fileName: filePath, tree: sourceFile)
    let snapshotRewriter = SnapshotRewriter(
      file: file,
      snapshots: snapshots.sorted {
        $0.line > $1.line
          && $0.syntaxDescriptor.trailingClosureOffset < $1.syntaxDescriptor.trailingClosureOffset
      },
      sourceLocationConverter: sourceLocationConverter
    )
    let updatedSource = snapshotRewriter.visit(sourceFile).description
    do {
      if source != updatedSource {
        try updatedSource.write(toFile: filePath, atomically: true, encoding: .utf8)
      }
      snapshotRewriter.report()
    } catch {
      XCTFail("Threw error: \(error)", file: file.path, line: line)
    }
  }
}

private final class SnapshotRewriter: SyntaxRewriter {
  let file: File
  var function: String?
  let indent: String
  let line: UInt?
  var offset = 0
  var newRecordings: [(snapshot: InlineSnapshot, line: UInt)] = []
  var snapshots: [InlineSnapshot]
  let sourceLocationConverter: SourceLocationConverter
  let wasRecording: Bool

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
    var functionCallExpr = functionCallExpr
    while let snapshot = snapshots.first,
      (functionCallExpr.position..<functionCallExpr.endPosition).contains(
        self.sourceLocationConverter.position(
          ofLine: Int(snapshot.line), column: Int(snapshot.column)
        )
      ),
      snapshot.expected != snapshot.actual
    {
      self.snapshots.removeFirst()

      let originalFunctionCallExpr = functionCallExpr
      self.function =
        self.function
        ?? functionCallExpr.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text
      var line: Int?

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

      let arguments = functionCallExpr.arguments
      let firstTrailingClosureOffset =
        arguments
        .enumerated()
        .reversed()
        .prefix(while: { $0.element.expression.is(ClosureExprSyntax.self) })
        .last?
        .offset
        ?? arguments.count

      let trailingClosureOffset =
        firstTrailingClosureOffset
        + snapshot.syntaxDescriptor.trailingClosureOffset

      let centeredTrailingClosureOffset = trailingClosureOffset - arguments.count

      switch centeredTrailingClosureOffset {
      case ..<0:
        let index = arguments.index(arguments.startIndex, offsetBy: trailingClosureOffset)
        functionCallExpr.arguments[index].expression = ExprSyntax(snapshotClosure)
        line = functionCallExpr.lineOffset(of: { $0.arguments[index].expression })

      case 0:
        if snapshot.wasRecording || functionCallExpr.trailingClosure == nil {
          functionCallExpr.rightParen?.trailingTrivia = .space
          functionCallExpr.trailingClosure = snapshotClosure
          line = functionCallExpr.lineOffset(of: { $0.trailingClosure })
        } else {
          fatalError()
        }

      case 1...:
        var newElement: MultipleTrailingClosureElementSyntax {
          MultipleTrailingClosureElementSyntax(
            label: TokenSyntax(stringLiteral: snapshot.syntaxDescriptor.trailingClosureLabel),
            closure: snapshotClosure.with(\.leadingTrivia, snapshotClosure.leadingTrivia + .space)
          )
        }

        if !functionCallExpr.additionalTrailingClosures.isEmpty,
          let endIndex = functionCallExpr.additionalTrailingClosures.index(
            functionCallExpr.additionalTrailingClosures.endIndex,
            offsetBy: -1,
            limitedBy: functionCallExpr.additionalTrailingClosures.startIndex
          ),
          let index = functionCallExpr.additionalTrailingClosures.index(
            functionCallExpr.additionalTrailingClosures.startIndex,
            offsetBy: centeredTrailingClosureOffset - 1,
            limitedBy: endIndex
          )
        {
          if functionCallExpr.additionalTrailingClosures[index].label.text
            == snapshot.syntaxDescriptor.trailingClosureLabel
          {
            if snapshot.wasRecording {
              functionCallExpr.additionalTrailingClosures[index].closure = snapshotClosure
            } else {
              return ExprSyntax(functionCallExpr)
            }
          } else {
            functionCallExpr.additionalTrailingClosures.insert(
              newElement.with(\.trailingTrivia, .space),
              at: index
            )
          }
          line = functionCallExpr.lineOffset(of: { $0.additionalTrailingClosures[index].label })
        } else if centeredTrailingClosureOffset >= 1 {
          if let index = functionCallExpr.additionalTrailingClosures.index(
            functionCallExpr.additionalTrailingClosures.endIndex,
            offsetBy: -1,
            limitedBy: functionCallExpr.additionalTrailingClosures.startIndex
          ) {
            functionCallExpr.additionalTrailingClosures[index].trailingTrivia = .space
          } else {
            functionCallExpr.trailingClosure?.trailingTrivia = .space
          }
          functionCallExpr.additionalTrailingClosures.append(newElement)
          line = functionCallExpr.lineOffset(of: { $0.additionalTrailingClosures.last?.label })
        } else {
          fatalError()
        }

      default:
        fatalError()
      }

      defer {
        let lineCount = originalFunctionCallExpr.description
          .split(separator: "\n", omittingEmptySubsequences: false)
          .count
        let updatedLineCount = functionCallExpr.description
          .split(separator: "\n", omittingEmptySubsequences: false)
          .count
        self.offset += updatedLineCount - lineCount
      }
      if snapshot.expected != snapshot.actual {
        self.newRecordings.append(
          (snapshot: snapshot, line: snapshot.line + UInt(line ?? 0))
        )
      }
    }
    return ExprSyntax(functionCallExpr)
  }

  func report() {
    guard !self.newRecordings.isEmpty else {
      XCTFail(
        self.wasRecording
          ? """
          Record mode is on. Turn record mode off and run tests again to assert against recorded \
          snapshots.
          """
          : """
          Could not assert against inline snapshot. Please file an issue with the author of \
          \(self.function.map { "\"\($0)\"" } ?? "this helper").
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

private extension SyntaxProtocol {
  func lineOffset(of child: (Self) -> (some SyntaxProtocol)?) -> Int? {
    guard let child = child(self) else { return nil }

    let trimmed = self.trimmed
    return trimmed.syntaxTextBytes[
      ..<(child.positionAfterSkippingLeadingTrivia.utf8Offset - trimmed.position.utf8Offset)
    ]
    .reduce(into: 0) { lines, byte in
      if byte == UTF8.CodeUnit(ascii: "\n") {
        lines += 1
      }
    }
  }
}

private final class SnapshotVisitor: SyntaxVisitor {
  let functionCallColumn: Int
  let functionCallLine: Int
  let sourceLocationConverter: SourceLocationConverter
  let syntaxDescriptor: InlineSnapshotSyntaxDescriptor
  var trailingClosureLine: Int?

  init(
    functionCallLine: Int,
    functionCallColumn: Int,
    sourceLocationConverter: SourceLocationConverter,
    syntaxDescriptor: InlineSnapshotSyntaxDescriptor
  ) {
    self.functionCallColumn = functionCallColumn
    self.functionCallLine = functionCallLine
    self.sourceLocationConverter = sourceLocationConverter
    self.syntaxDescriptor = syntaxDescriptor
    super.init(viewMode: .all)
  }

  override func visit(_ functionCallExpr: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
    guard
      (functionCallExpr.position..<functionCallExpr.endPosition).contains(
        self.sourceLocationConverter.position(
          ofLine: Int(self.functionCallLine), column: Int(self.functionCallColumn)
        )
      )
    else { return .visitChildren }

    let arguments = functionCallExpr.arguments
    let firstTrailingClosureOffset =
      arguments
      .enumerated()
      .reversed()
      .prefix(while: { $0.element.expression.is(ClosureExprSyntax.self) })
      .last?
      .offset
      ?? arguments.count

    let trailingClosureOffset =
      firstTrailingClosureOffset
      + self.syntaxDescriptor.trailingClosureOffset

    let centeredTrailingClosureOffset = trailingClosureOffset - arguments.count

    switch centeredTrailingClosureOffset {
    case ..<0:
      let index = arguments.index(arguments.startIndex, offsetBy: trailingClosureOffset)
      self.trailingClosureLine =
        arguments[index]
        .startLocation(converter: self.sourceLocationConverter)
        .line

    case 0:
      self.trailingClosureLine = functionCallExpr.trailingClosure.map {
        $0
          .startLocation(converter: self.sourceLocationConverter)
          .line
      }

    case 1...:
      self.trailingClosureLine =
        functionCallExpr.additionalTrailingClosures[
          functionCallExpr.additionalTrailingClosures.index(
            functionCallExpr.additionalTrailingClosures.startIndex,
            offsetBy: centeredTrailingClosureOffset - 1
          )
        ]
        .startLocation(converter: self.sourceLocationConverter)
        .line
    default:
      break
    }
    return .skipChildren
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
