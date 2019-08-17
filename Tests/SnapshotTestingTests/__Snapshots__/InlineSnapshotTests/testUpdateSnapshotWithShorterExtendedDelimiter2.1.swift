import XCTest
@testable import SnapshotTesting
extension InlineSnapshotsValidityTests {
  func testUpdateSnapshotWithShorterExtendedDelimiter2() {
    let diffable = #######"""
    \"""#
    """#######

    assertInlineSnapshot(matching: diffable, as: .lines, with: ##"""
    \"""#
    """##)
  }
}