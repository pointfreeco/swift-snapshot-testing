//
//  InlineSnapshotTests.swift
//  SnapshotTesting
//
//  Created by Ferran Pujol Camins on 21/05/2019.
//

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

    let context1 = Context(sourceCode: source, diffable: "NEW_SNAPSHOT\nwith two lines", fileName: "filename", lineIndex: 2)
    let context2 = { (context: Context) in
      Context(sourceCode: context.sourceCode, diffable: "NEW_SNAPSHOT", fileName: "filename", lineIndex: 6)
    }

    let testExecution = context1 >>> writeInlineSnapshot
      >>> context2 >>> writeInlineSnapshot

    var recordings: Recordings = [:]
    let newSource = testExecution(&recordings).sourceCode

    assertSnapshot(matching: newSource, as: .lines)
  }
}
