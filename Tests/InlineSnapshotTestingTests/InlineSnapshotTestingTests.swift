import Foundation
import InlineSnapshotTesting
import SnapshotTesting
import XCTest

final class SnapshotTestingTests: XCTestCase {
  override func setUp() {
    super.setUp()
    diffTool = "ksdiff"
    //isRecording = true
  }

  override func tearDown() {
    isRecording = false
    super.tearDown()
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
    assertInlineSnapshot(of: ["Hello", "World"], as: .dump, matches: {
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
      })
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
