import XCTest
@testable import SnapshotTesting
extension InlineSnapshotsValidityTests {
  func testCreateSnapshotWithShorterExtendedDelimiter1() {
    let diffable = #######"""
    \"
    """#######

    assertInlineSnapshot(matching: diffable, as: .lines, with: #"""
    \"
    """#)
  }
}