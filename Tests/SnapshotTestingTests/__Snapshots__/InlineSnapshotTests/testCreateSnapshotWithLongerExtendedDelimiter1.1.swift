import XCTest
@testable import SnapshotTesting
extension InlineSnapshotsValidityTests {
  func testCreateSnapshotWithLongerExtendedDelimiter1() {
    let diffable = #######"""
    \"
    """#######

    assertInlineSnapshot(matching: diffable, as: .lines, with: #"""
    \"
    """#)
  }
}