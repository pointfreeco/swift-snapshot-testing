import XCTest
@testable import SnapshotTesting

class InlineSnapshotTests: XCTestCase {

  func testCreateSnapshotSingleLine() {
    let source = #"""
    _assertInlineSnapshot(matching: post, as: .raw(pretty: true), with: "")
    """#

    var recordings: Recordings = [:]
    let newSource = writeInlineSnapshot(
      &recordings,
      Context(sourceCode: source, diffable: "NEW_SNAPSHOT", fileName: "filename", lineIndex: 1)
    ).sourceCode

    assertSnapshot(matching: newSource, as: .lines)
  }

  func testCreateSnapshotMultiLine() {
    let source = """
    _assertInlineSnapshot(matching: post, as: .raw(pretty: true), with: \"""
    \""")
    """

    var recordings: Recordings = [:]
    let newSource = writeInlineSnapshot(
      &recordings,
      Context(sourceCode: source, diffable: "NEW_SNAPSHOT", fileName: "filename", lineIndex: 1)
    ).sourceCode

    assertSnapshot(matching: newSource, as: .lines)
  }

  func testUpdateSnapshot() {
    let source = """
    _assertInlineSnapshot(matching: post, as: .raw(pretty: true), with: \"""
    OLD_SNAPSHOT
    \""")
    """

    var recordings: Recordings = [:]
    let newSource = writeInlineSnapshot(
      &recordings,
      Context(sourceCode: source, diffable: "NEW_SNAPSHOT", fileName: "filename", lineIndex: 1)
    ).sourceCode

    assertSnapshot(matching: newSource, as: .lines)
  }

  func testUpdateSeveralSnapshots() {
    let source = """
    class InlineSnapshotTests: XCTestCase {
      _assertInlineSnapshot(matching: post, as: .raw(pretty: true), with: \"""
      OLD_SNAPSHOT
      \""")

      _assertInlineSnapshot(matching: post, as: .raw(pretty: true), with: \"""
      OLD_SNAPSHOT
      \""")
    }
    """

    var recordings: Recordings = [:]
    let context1 = Context(sourceCode: source, diffable: "NEW_SNAPSHOT\nwith two lines", fileName: "filename", lineIndex: 2)
    let contextAfterFirstSnapshot = writeInlineSnapshot(&recordings, context1)

    let context2 = Context(sourceCode: contextAfterFirstSnapshot.sourceCode, diffable: "NEW_SNAPSHOT", fileName: "filename", lineIndex: 6)
    let newSource = writeInlineSnapshot(&recordings, context2).sourceCode

    assertSnapshot(matching: newSource, as: .lines)
  }
}
