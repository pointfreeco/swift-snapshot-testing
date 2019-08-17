import XCTest
@testable import SnapshotTesting
extension InlineSnapshotsValidityTests {
  func testUpdateSnapshotWithLongerExtendedDelimiter1() {
    let diffable = #######"""
    \"
    """#######

    assertInlineSnapshot(matching: diffable, as: .lines, with: #"""
    \"
    """#)
  }
}