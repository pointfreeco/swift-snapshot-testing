import Foundation
import InlineSnapshotTesting
import SnapshotTesting
import XCTest

final class InlineSnapshotTestingTests: XCTestCase {
  override func setUp() {
    super.setUp()
    SnapshotTesting.diffTool = "ksdiff"
    // SnapshotTesting.isRecording = true
  }

  override func tearDown() {
    SnapshotTesting.isRecording = false
    super.tearDown()
  }

  func testInlineSnapshot() async {
    await assertInlineSnapshot(of: ["Hello", "World"], as: .dump) {
      """
      ▿ 2 elements
        - "Hello"
        - "World"

      """
    }
  }

  func testInlineSnapshot_NamedTrailingClosure() async {
    await assertInlineSnapshot(of: ["Hello", "World"], as: .dump, matches: {
      """
      ▿ 2 elements
        - "Hello"
        - "World"

      """
    })
  }

  func testInlineSnapshot_Escaping() async {
    await assertInlineSnapshot(of: "Hello\"\"\"#, world", as: .lines) {
      ##"""
      Hello"""#, world
      """##
    }
  }

  func testCustomInlineSnapshot() async {
    await assertCustomInlineSnapshot {
      "Hello"
    } is: {
      """
      - "Hello"

      """
    }
  }

  func testCustomInlineSnapshot_Multiline() async {
    await assertCustomInlineSnapshot {
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

  func testCustomInlineSnapshot_SingleTrailingClosure() async {
    await assertCustomInlineSnapshot(of: { "Hello" }) {
      """
      - "Hello"

      """
    }
  }

  func testCustomInlineSnapshot_MultilineSingleTrailingClosure() async {
    await assertCustomInlineSnapshot(
      of: { "Hello" }
    ) {
      """
      - "Hello"

      """
    }
  }

  func testCustomInlineSnapshot_NoTrailingClosure() async {
    await assertCustomInlineSnapshot(
      of: { "Hello" },
      is: {
        """
        - "Hello"

        """
      }
    )
  }

  func testMultipleInlineSnapshots() async {
    func assertResponse(
      of url: () -> String,
      head: (() -> String)? = nil,
      body: (() -> String)? = nil,
      file: StaticString = #filePath,
      function: StaticString = #function,
      line: UInt = #line,
      column: UInt = #column
    ) async {
      await assertInlineSnapshot(
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
      await assertInlineSnapshot(
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

    await assertResponse {
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
}

private func assertCustomInlineSnapshot(
  of value: @escaping () -> String,
  is expected: (() -> String)? = nil,
  file: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) async {
  await assertInlineSnapshot(
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
