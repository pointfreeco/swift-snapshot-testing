import XCTest
@testable import SnapshotTesting
extension InlineSnapshotsValidityTests {
  func testCreateSnapshotWithExtendedDelimiter1() {
    let diffable = #######"""
    \"
    """#######

    assertInlineSnapshot(matching: diffable, as: .lines, with: #"""
    \"
    """#)
  }
}