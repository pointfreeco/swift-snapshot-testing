import Foundation
import InlineSnapshotTesting
import SnapshotTesting
import XCTest

final class InlineSnapshotTestingTests: XCTestCase {
  override func invokeTest() {
    SnapshotTesting.diffTool = "ksdiff"
    // SnapshotTesting.isRecording = true
    defer {
      SnapshotTesting.diffTool = nil
      SnapshotTesting.isRecording = false
    }
    super.invokeTest()
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
      file: StaticString = #filePath,
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
        file: file,
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
      file: StaticString = #filePath,
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
        file: file,
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
        file: file,
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
      file: StaticString = #filePath,
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
        file: file,
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
}

private func assertCustomInlineSnapshot(
  of value: () -> String,
  is expected: (() -> String)? = nil,
  file: StaticString = #filePath,
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
    file: file,
    function: function,
    line: line,
    column: column
  )
}
