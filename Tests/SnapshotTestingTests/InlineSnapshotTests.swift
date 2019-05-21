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
    XCTAssertEqual(newSource, """
    _assertInlineSnapshot(matching: post, as: .raw(pretty: true), with: \"""
    NEW_SNAPSHOT
    \""")
    """)
  }

  func testCreateSnapshotMultiLine() {
    let source = """
    _assertInlineSnapshot(matching: post, as: .raw(pretty: true), with: \"""
    \""")
    """
    let writingFunction = writeInlineSnapshot(diffable: "NEW_SNAPSHOT", fileName: "filename", lineIndex: 1)
    let newSource = writingFunction(pure(source)).eval([:])
    XCTAssertEqual(newSource, """
    _assertInlineSnapshot(matching: post, as: .raw(pretty: true), with: \"""
    NEW_SNAPSHOT
    \""")
    """)
  }

  func testUpdateSnapshot() {
    let source = """
    _assertInlineSnapshot(matching: post, as: .raw(pretty: true), with: \"""
    OLD_SNAPSHOT
    \""")
    """
    let writingFunction = writeInlineSnapshot(diffable: "NEW_SNAPSHOT", fileName: "filename", lineIndex: 1)
    let newSource = writingFunction(pure(source)).eval([:])
    XCTAssertEqual(newSource, """
    _assertInlineSnapshot(matching: post, as: .raw(pretty: true), with: \"""
    NEW_SNAPSHOT
    \""")
    """)
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
    let writingFunction1 = writeInlineSnapshot(diffable: "NEW_SNAPSHOT\nwith two lines", fileName: "filename", lineIndex: 2)
    let writingFunction2 = writeInlineSnapshot(diffable: "NEW_SNAPSHOT", fileName: "filename", lineIndex: 6)

    let testExecution = pure
      >>> writingFunction1
      >>> writingFunction2
    let newSource = testExecution(source).eval([:])

    XCTAssertEqual(newSource, """
    class InlineSnapshotTests: XCTestCase {
      _assertInlineSnapshot(matching: post, as: .raw(pretty: true), with: \"""
      NEW_SNAPSHOT
      with two lines
      \""")

      _assertInlineSnapshot(matching: post, as: .raw(pretty: true), with: \"""
      NEW_SNAPSHOT
      \""")
    }
    """)
  }
}
