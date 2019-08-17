import XCTest
@testable import SnapshotTesting
extension InlineSnapshotsValidityTests {
  func testUpdateSnapshotWithLongerExtendedDelimiter2() {
    let diffable = #######"""
    \"""#
    """#######

    assertInlineSnapshot(matching: diffable, as: .lines, with: ##"""
    \"""#
    """##)
  }
}