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
    let writingFunction = writeInlineSnapshot(diffable: "NEW_SNAPSHOT", fileName: "filename", lineIndex: 1)
    let newSource = writingFunction(pure(source)).eval([:])
    assertSnapshot(matching: newSource, as: .lines)
  }

  func testCreateSnapshotMultiLine() {
    let source = """
    _assertInlineSnapshot(matching: post, as: .raw(pretty: true), with: \"""
    \""")
    """
    let writingFunction = writeInlineSnapshot(diffable: "NEW_SNAPSHOT", fileName: "filename", lineIndex: 1)
    let newSource = writingFunction(pure(source)).eval([:])
    assertSnapshot(matching: newSource, as: .lines)
  }

  func testUpdateSnapshot() {
    let source = """
    _assertInlineSnapshot(matching: post, as: .raw(pretty: true), with: \"""
    OLD_SNAPSHOT
    \""")
    """
    let writingFunction = writeInlineSnapshot(diffable: "NEW_SNAPSHOT", fileName: "filename", lineIndex: 1)
    let newSource = writingFunction(pure(source)).eval([:])

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
    let writeSnapshot1 = writeInlineSnapshot(diffable: "NEW_SNAPSHOT\nwith two lines", fileName: "filename", lineIndex: 2)
    let writeSnapshot2 = writeInlineSnapshot(diffable: "NEW_SNAPSHOT", fileName: "filename", lineIndex: 6)

    let testExecution = pure
      >>> writeSnapshot1
      >>> writeSnapshot2
    let newSource = testExecution(source).eval([:])

    assertSnapshot(matching: newSource, as: .lines)
  }
}
