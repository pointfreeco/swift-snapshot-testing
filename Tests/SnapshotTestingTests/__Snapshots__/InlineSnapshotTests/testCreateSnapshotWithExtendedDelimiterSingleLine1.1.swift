import XCTest
@testable import SnapshotTesting
extension InlineSnapshotsValidityTests {
  func testCreateSnapshotWithExtendedDelimiterSingleLine1() {
    let diffable = #######"""
    \"
    """#######

    assertInlineSnapshot(matching: diffable, as: .lines, with: #"""
    \"
    """#)
  }
}