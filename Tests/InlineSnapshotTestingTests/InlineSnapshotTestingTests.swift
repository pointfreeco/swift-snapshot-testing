import Foundation
@_spi(Internals) import InlineSnapshotTesting
import SnapshotTesting
import XCTest

final class InlineSnapshotTestingTests: XCTestCase {
  override func invokeTest() {
    withSnapshotTesting(record: .missing, diffTool: .ksdiff) {
      super.invokeTest()
    }
  }

  func testInlineSnapshot() {
    assertInlineSnapshot(of: ["Hello", "World"], as: .dump) {
      """
      ▿ 2 elements
        - "Hello"
        - "World"

      """
    }
  }

  func testInlineSnapshot_NamedTrailingClosure() {
    assertInlineSnapshot(
      of: ["Hello", "World"], as: .dump,
      matches: {
        """
        ▿ 2 elements
          - "Hello"
          - "World"

        """
      })
  }

  func testInlineSnapshot_Escaping() {
    assertInlineSnapshot(of: "Hello\"\"\"#, world", as: .lines) {
      ##"""
      Hello"""#, world
      """##
    }
  }

  func testCustomInlineSnapshot() {
    assertCustomInlineSnapshot {
      "Hello"
    } is: {
      """
      - "Hello"

      """
    }
  }

  func testCustomInlineSnapshot_Multiline() {
    assertCustomInlineSnapshot {
      """
      "Hello"
      "World"
      """
    } is: {
      #"""
      - "\"Hello\"\n\"World\""

      """#
    }
  }

  func testCustomInlineSnapshot_SingleTrailingClosure() {
    assertCustomInlineSnapshot(of: { "Hello" }) {
      """
      - "Hello"

      """
    }
  }

  func testCustomInlineSnapshot_MultilineSingleTrailingClosure() {
    assertCustomInlineSnapshot(
      of: { "Hello" }
    ) {
      """
      - "Hello"

      """
    }
  }

  func testCustomInlineSnapshot_NoTrailingClosure() {
    assertCustomInlineSnapshot(
      of: { "Hello" },
      is: {
        """
        - "Hello"

        """
      }
    )
  }

  func testArgumentlessInlineSnapshot() {
    func assertArgumentlessInlineSnapshot(
      expected: (() -> String)? = nil,
      fileID: StaticString = #fileID,
      file filePath: StaticString = #filePath,
      function: StaticString = #function,
      line: UInt = #line,
      column: UInt = #column
    ) {
      assertInlineSnapshot(
        of: "Hello",
        as: .dump,
        syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
          trailingClosureLabel: "is",
          trailingClosureOffset: 1
        ),
        matches: expected,
        fileID: fileID,
        file: filePath,
        function: function,
        line: line,
        column: column
      )
    }

    assertArgumentlessInlineSnapshot {
      """
      - "Hello"

      """
    }
  }

  func testMultipleInlineSnapshots() {
    func assertResponse(
      of url: () -> String,
      head: (() -> String)? = nil,
      body: (() -> String)? = nil,
      fileID: StaticString = #fileID,
      file filePath: StaticString = #filePath,
      function: StaticString = #function,
      line: UInt = #line,
      column: UInt = #column
    ) {
      assertInlineSnapshot(
        of: """
          HTTP/1.1 200 OK
          Content-Type: text/html; charset=utf-8
          """,
        as: .lines,
        message: "Head did not match",
        syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
          trailingClosureLabel: "head",
          trailingClosureOffset: 1
        ),
        matches: head,
        fileID: fileID,
        file: filePath,
        function: function,
        line: line,
        column: column
      )
      assertInlineSnapshot(
        of: """
          <!doctype html>
          <html lang="en">
          <head>
            <meta charset="utf-8">
            <title>Point-Free</title>
            <link rel="stylesheet" href="style.css">
          </head>
          <body>
            <p>What's the point?</p>
          </body>
          </html>
          """,
        as: .lines,
        message: "Body did not match",
        syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
          trailingClosureLabel: "body",
          trailingClosureOffset: 2
        ),
        matches: body,
        fileID: fileID,
        file: filePath,
        function: function,
        line: line,
        column: column
      )
    }

    assertResponse {
      """
      https://www.pointfree.co/
      """
    } head: {
      """
      HTTP/1.1 200 OK
      Content-Type: text/html; charset=utf-8
      """
    } body: {
      """
      <!doctype html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <title>Point-Free</title>
        <link rel="stylesheet" href="style.css">
      </head>
      <body>
        <p>What's the point?</p>
      </body>
      </html>
      """
    }
  }

  func testAsyncThrowing() async throws {
    func assertAsyncThrowingInlineSnapshot(
      of value: () -> String,
      is expected: (() -> String)? = nil,
      fileID: StaticString = #fileID,
      file filePath: StaticString = #filePath,
      function: StaticString = #function,
      line: UInt = #line,
      column: UInt = #column
    ) async throws {
      assertInlineSnapshot(
        of: value(),
        as: .dump,
        syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
          trailingClosureLabel: "is",
          trailingClosureOffset: 1
        ),
        matches: expected,
        fileID: fileID,
        file: filePath,
        function: function,
        line: line,
        column: column
      )
    }

    try await assertAsyncThrowingInlineSnapshot {
      "Hello"
    } is: {
      """
      - "Hello"

      """
    }
  }

  func testNestedInClosureFunction() {
    func withDependencies(operation: () -> Void) {
      operation()
    }

    withDependencies {
      assertInlineSnapshot(of: "Hello", as: .dump) {
        """
        - "Hello"

        """
      }
    }
  }

  func testCarriageReturnInlineSnapshot() {
    assertInlineSnapshot(of: "This is a line\r\nAnd this is a line\r\n", as: .lines) {
      """
      This is a line\r
      And this is a line\r

      """
    }
  }

  func testCarriageReturnRawInlineSnapshot() {
    assertInlineSnapshot(of: "\"\"\"#This is a line\r\nAnd this is a line\r\n", as: .lines) {
      ##"""
      """#This is a line\##r
      And this is a line\##r

      """##
    }
  }

  #if canImport(Darwin)
    func testRecordFailed_IncorrectExpectation() throws {
      let initialInlineSnapshotState = inlineSnapshotState
      defer { inlineSnapshotState = initialInlineSnapshotState }

      XCTExpectFailure {
        withSnapshotTesting(record: .failed) {
          assertInlineSnapshot(of: 42, as: .json) {
            """
            4
            """
          }
        }
      } issueMatcher: {
        $0.compactDescription == """
          failed - Snapshot did not match. Difference: …

            @@ −1,1 +1,1 @@
            −4
            +42

          A new snapshot was automatically recorded.
          """
      }

      XCTAssertEqual(inlineSnapshotState.count, 1)
      XCTAssertEqual(
        String(describing: inlineSnapshotState.keys.first!.path)
          .hasSuffix("InlineSnapshotTestingTests.swift"),
        true
      )
    }
  #endif

  #if canImport(Darwin)
    func testRecordFailed_MissingExpectation() throws {
      let initialInlineSnapshotState = inlineSnapshotState
      defer { inlineSnapshotState = initialInlineSnapshotState }

      XCTExpectFailure {
        withSnapshotTesting(record: .failed) {
          assertInlineSnapshot(of: 42, as: .json)
        }
      } issueMatcher: {
        $0.compactDescription == """
          failed - Automatically recorded a new snapshot. Difference: …

            @@ −1,1 +1,1 @@
            −
            +42

          Re-run "testRecordFailed_MissingExpectation()" to assert against the newly-recorded snapshot.
          """
      }

      XCTAssertEqual(inlineSnapshotState.count, 1)
      XCTAssertEqual(
        String(describing: inlineSnapshotState.keys.first!.path)
          .hasSuffix("InlineSnapshotTestingTests.swift"),
        true
      )
    }
  #endif
}

private func assertCustomInlineSnapshot(
  of value: () -> String,
  is expected: (() -> String)? = nil,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) {
  assertInlineSnapshot(
    of: value(),
    as: .dump,
    syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
      trailingClosureLabel: "is",
      trailingClosureOffset: 1
    ),
    matches: expected,
    fileID: fileID,
    file: filePath,
    function: function,
    line: line,
    column: column
  )
}
