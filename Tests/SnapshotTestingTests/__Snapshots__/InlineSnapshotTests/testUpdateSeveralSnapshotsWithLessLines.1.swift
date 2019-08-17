import XCTest
@testable import SnapshotTesting
extension InlineSnapshotsValidityTests {
  func testUpdateSeveralSnapshotsWithLessLines() {
    let diffable = #######"""
    NEW_SNAPSHOT
    """#######

    let diffable2 = #######"""
    NEW_SNAPSHOT
    """#######

    assertInlineSnapshot(matching: diffable, as: .lines, with: """
    NEW_SNAPSHOT
    """)
    assertInlineSnapshot(matching: diffable2, as: .lines, with: """
    NEW_SNAPSHOT
    """)
   }
}