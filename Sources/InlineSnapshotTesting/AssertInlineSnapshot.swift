import Foundation

#if canImport(SwiftSyntax509)
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
  ///   - isRecording: Whether or not to record a new reference.
  ///   - timeout: The amount of time a snapshot must be generated in.
  ///   - syntaxDescriptor: An optional description of where the snapshot is inlined. This parameter
  ///     should be omitted unless you are writing a custom helper that calls this function under
  ///     the hood. See ``InlineSnapshotSyntaxDescriptor`` for more.
  ///   - expected: An optional closure that returns a previously generated snapshot. When omitted,
  ///     the library will automatically write a snapshot into your test file at the call sight of
  ///     the assertion.
  ///   - file: The file where the assertion occurs. The default is the filename of the test case
  ///     where you call this function.
  ///   - function: The function where the assertion occurs. The default is the name of the test
  ///     method where you call this function.
  ///   - line: The line where the assertion occurs. The default is the line number where you call
  ///     this function.
  ///   - column: The column where the assertion occurs. The default is the line column you call
  ///     this function.
  public func assertInlineSnapshot<Value>(
    of value: @autoclosure () throws -> Value,
    as snapshotting: Snapshotting<Value, String>,
    message: @autoclosure () -> String = "",
    record isRecording: Bool = isRecording,
    timeout: TimeInterval = 5,
    syntaxDescriptor: InlineSnapshotSyntaxDescriptor = InlineSnapshotSyntaxDescriptor(),
    matches expected: (() -> String)? = nil,
    file: StaticString = #filePath,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
  ) {
    let _: Void = installTestObserver
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
        // NB: Write snapshot state before calling `XCTFail` in case `continueAfterFailure = false`
        inlineSnapshotState[File(path: file), default: []].append(
          InlineSnapshot(
            expected: expected?(),
            actual: actual,
            wasRecording: isRecording,
            syntaxDescriptor: syntaxDescriptor,
            function: "\(function)",
            line: line,
            column: column
          )
        )

        var failure: String
        if syntaxDescriptor.trailingClosureLabel
          == InlineSnapshotSyntaxDescriptor.defaultTrailingClosureLabel
        {
          failure = "Automatically recorded a new snapshot."
        } else {
          failure = """
            Automatically recorded a new snapshot for "\(syntaxDescriptor.trailingClosureLabel)".
            """
        }
        if let expected = expected?(),
          let difference = snapshotting.diffing.diff(expected, actual)?.0
        {
          failure += " Difference: …\n\n\(difference.indenting(by: 2))"
        }
        XCTFail(
          """
          \(failure)

          Re-run "\(function)" to assert against the newly-recorded snapshot.
          """,
          file: file,
          line: line
        )
        return
      }
      guard let difference = snapshotting.diffing.diff(expected, actual)?.0
      else { return }

      let message = message()
      syntaxDescriptor.fail(
        """
        \(message.isEmpty ? "Snapshot did not match. Difference: …" : message)

        \(difference.indenting(by: 2))
        """,
        file: file,
        line: line,
        column: column
      )
    } catch {
      XCTFail("Threw error: \(error)", file: file, line: line)
    }
  }
#else
  @available(*, unavailable, message: "'assertInlineSnapshot' requires 'swift-syntax' >= 509.0.0")
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
    fatalError()
  }
#endif

/// A structure that describes the location of an inline snapshot.
///
/// Provide this structure when defining custom snapshot functions that call
/// ``assertInlineSnapshot(of:as:message:record:timeout:syntaxDescriptor:matches:file:function:line:column:)``
/// under the hood.
public struct InlineSnapshotSyntaxDescriptor: Hashable {
  /// The default label describing an inline snapshot.
  public static let defaultTrailingClosureLabel = "matches"

  /// A list of trailing closure labels from deprecated interfaces.
  ///
  /// Useful for providing migration paths for custom snapshot functions.
  public var deprecatedTrailingClosureLabels: [String]

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
  public init(
    deprecatedTrailingClosureLabels: [String] = [],
    trailingClosureLabel: String = Self.defaultTrailingClosureLabel,
    trailingClosureOffset: Int = 0
  ) {
    self.deprecatedTrailingClosureLabels = deprecatedTrailingClosureLabels
    self.trailingClosureLabel = trailingClosureLabel
    self.trailingClosureOffset = trailingClosureOffset
  }

  #if canImport(SwiftSyntax509)
    /// Generates a test failure immediately and unconditionally at the described trailing closure.
    ///
    /// This method will attempt to locate the line of the trailing closure described by this type
    /// and call `XCTFail` with it. If the trailing closure cannot be located, the failure will be
    /// associated with the given line, instead.
    ///
    /// - Parameters:
    ///   - message: An optional description of the assertion, for inclusion in test results.
    ///   - file: The file where the assertion occurs. The default is the filename of the test case
    ///     where you call `assertInlineSnapshot`.
    ///   - line: The line where the assertion occurs. The default is the line number where you call
    ///     `assertInlineSnapshot`.
    ///   - column: The column where the assertion occurs. The default is the column where you call
    ///     `assertInlineSnapshot`.
    public func fail(
      _ message: @autoclosure () -> String = "",
      file: StaticString,
      line: UInt,
      column: UInt
    ) {
      var trailingClosureLine: Int?
      if let testSource = try? testSource(file: File(path: file)) {
        let visitor = SnapshotVisitor(
          functionCallLine: Int(line),
          functionCallColumn: Int(column),
          sourceLocationConverter: testSource.sourceLocationConverter,
          syntaxDescriptor: self
        )
        visitor.walk(testSource.sourceFile)
        trailingClosureLine = visitor.trailingClosureLine
      }
      XCTFail(
        message(),
        file: file,
        line: trailingClosureLine.map(UInt.init) ?? line
      )
    }

    fileprivate func contains(_ label: String) -> Bool {
      self.trailingClosureLabel == label || self.deprecatedTrailingClosureLabels.contains(label)
    }
  #else
    @available(*, unavailable, message: "'assertInlineSnapshot' requires 'swift-syntax' >= 509.0.0")
    public func fail(
      _ message: @autoclosure () -> String = "",
      file: StaticString,
      line: UInt,
      column: UInt
    ) {
      fatalError()
    }
  #endif
}

// MARK: - Private

#if canImport(SwiftSyntax509)
  private let installTestObserver: Void = {
    final class InlineSnapshotObserver: NSObject, XCTestObservation {
      func testBundleDidFinish(_ testBundle: Bundle) {
        writeInlineSnapshots()
      }
    }
    DispatchQueue.mainSync {
      XCTestObservationCenter.shared.addTestObserver(InlineSnapshotObserver())
    }
  }()

  extension DispatchQueue {
    private static let key = DispatchSpecificKey<UInt8>()
    private static let value: UInt8 = 0

    fileprivate static func mainSync<R>(execute block: () -> R) -> R {
      Self.main.setSpecific(key: key, value: value)
      if getSpecific(key: key) == value {
        return block()
      } else {
        return main.sync(execute: block)
      }
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
    var wasRecording: Bool
    var syntaxDescriptor: InlineSnapshotSyntaxDescriptor
    var function: String
    var line: UInt
    var column: UInt
  }

  private var inlineSnapshotState: [File: [InlineSnapshot]] = [:]

  private struct TestSource {
    let source: String
    let sourceFile: SourceFileSyntax
    let sourceLocationConverter: SourceLocationConverter
  }

  private func testSource(file: File) throws -> TestSource {
    guard let testSource = testSourceCache[file]
    else {
      let filePath = "\(file.path)"
      let source = try String(contentsOfFile: filePath)
      let sourceFile = Parser.parse(source: source)
      let sourceLocationConverter = SourceLocationConverter(fileName: filePath, tree: sourceFile)
      let testSource = TestSource(
        source: source,
        sourceFile: sourceFile,
        sourceLocationConverter: sourceLocationConverter
      )
      testSourceCache[file] = testSource
      return testSource
    }
    return testSource
  }

  private var testSourceCache: [File: TestSource] = [:]

  private func writeInlineSnapshots() {
    defer { inlineSnapshotState.removeAll() }
    for (file, snapshots) in inlineSnapshotState {
      let line = snapshots.first?.line ?? 1
      guard let testSource = try? testSource(file: file)
      else {
        fatalError("Couldn't load snapshot from disk", file: file.path, line: line)
      }
      let snapshotRewriter = SnapshotRewriter(
        file: file,
        snapshots: snapshots.sorted {
          $0.line != $1.line
            ? $0.line < $1.line
            : $0.syntaxDescriptor.trailingClosureOffset < $1.syntaxDescriptor.trailingClosureOffset
        },
        sourceLocationConverter: testSource.sourceLocationConverter
      )
      let updatedSource = snapshotRewriter.visit(testSource.sourceFile).description
      do {
        if testSource.source != updatedSource {
          try updatedSource.write(toFile: "\(file.path)", atomically: true, encoding: .utf8)
        }
      } catch {
        fatalError("Threw error: \(error)", file: file.path, line: line)
      }
    }
  }

  private final class SnapshotRewriter: SyntaxRewriter {
    let file: File
    var function: String?
    let indent: String
    let line: UInt?
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
      let location = functionCallExpr.calledExpression
        .endLocation(converter: self.sourceLocationConverter, afterTrailingTrivia: true)
      let snapshots = self.snapshots.prefix { snapshot in
        Int(snapshot.line) == location.line && Int(snapshot.column) == location.column
      }

      guard !snapshots.isEmpty
      else { return super.visit(functionCallExpr) }

      defer { self.snapshots.removeFirst(snapshots.count) }

      var functionCallExpr = functionCallExpr
      for snapshot in snapshots {
        guard snapshot.expected != snapshot.actual else { continue }

        self.function =
          self.function
          ?? functionCallExpr.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text

        let leadingTrivia = String(
          self.sourceLocationConverter.sourceLines[Int(snapshot.line) - 1]
            .prefix(while: { $0 == " " || $0 == "\t" })
        )
        let delimiter = String(
          repeating: "#", count: snapshot.actual.hashCount(isMultiline: true)
        )
        let leadingIndent = leadingTrivia + self.indent
        let snapshotLabel = TokenSyntax(
          stringLiteral: snapshot.syntaxDescriptor.trailingClosureLabel
        )
        let snapshotClosure = ClosureExprSyntax(
          leftBrace: .leftBraceToken(trailingTrivia: .newline),
          statements: CodeBlockItemListSyntax {
            StringLiteralExprSyntax(
              leadingTrivia: Trivia(stringLiteral: leadingIndent),
              openingPounds: .rawStringPoundDelimiter(delimiter),
              openingQuote: .multilineStringQuoteToken(trailingTrivia: .newline),
              segments: [
                .stringSegment(
                  StringSegmentSyntax(
                    content: .stringSegment(
                      snapshot.actual
                        .replacingOccurrences(of: "\r", with: #"\\#(delimiter)r"#)
                        .indenting(with: leadingIndent)
                    )
                  )
                )
              ],
              closingQuote: .multilineStringQuoteToken(
                leadingTrivia: .newline + Trivia(stringLiteral: leadingIndent)
              ),
              closingPounds: .rawStringPoundDelimiter(delimiter)
            )
          },
          rightBrace: .rightBraceToken(
            leadingTrivia: .newline + Trivia(stringLiteral: leadingTrivia)
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
          functionCallExpr.arguments[index].label = snapshotLabel
          functionCallExpr.arguments[index].expression = ExprSyntax(snapshotClosure)

        case 0:
          if snapshot.wasRecording || functionCallExpr.trailingClosure == nil {
            functionCallExpr.rightParen?.trailingTrivia = .space
            functionCallExpr.trailingClosure = snapshotClosure
          } else {
            fatalError()
          }

        case 1...:
          var newElement: MultipleTrailingClosureElementSyntax {
            MultipleTrailingClosureElementSyntax(
              label: snapshotLabel,
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
            if snapshot.syntaxDescriptor.contains(
              functionCallExpr.additionalTrailingClosures[index].label.text
            ) {
              if snapshot.wasRecording {
                functionCallExpr.additionalTrailingClosures[index].label = snapshotLabel
                functionCallExpr.additionalTrailingClosures[index].closure = snapshotClosure
              }
            } else {
              functionCallExpr.additionalTrailingClosures.insert(
                newElement.with(\.trailingTrivia, .space),
                at: index
              )
            }
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
          } else {
            fatalError()
          }

        default:
          fatalError()
        }
      }

      if functionCallExpr.arguments.isEmpty,
        functionCallExpr.trailingClosure != nil,
        functionCallExpr.leftParen != nil,
        functionCallExpr.rightParen != nil
      {
        functionCallExpr.leftParen = nil
        functionCallExpr.rightParen = nil
        functionCallExpr.calledExpression.trailingTrivia = .space
      }

      return ExprSyntax(functionCallExpr)
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
      let location = functionCallExpr.calledExpression
        .endLocation(converter: self.sourceLocationConverter, afterTrailingTrivia: true)
      guard
        self.functionCallLine == location.line,
        self.functionCallColumn == location.column
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
        let index = functionCallExpr.additionalTrailingClosures.index(
          functionCallExpr.additionalTrailingClosures.startIndex,
          offsetBy: centeredTrailingClosureOffset - 1
        )
        if centeredTrailingClosureOffset - 1 < functionCallExpr.additionalTrailingClosures.count {
          self.trailingClosureLine =
            functionCallExpr.additionalTrailingClosures[index]
            .startLocation(converter: self.sourceLocationConverter)
            .line
        }
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
#endif
