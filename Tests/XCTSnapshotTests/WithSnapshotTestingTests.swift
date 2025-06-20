@_spi(Internals) @testable import XCTSnapshot
import XCTest

class WithSnapshotTestingTests: XCTestCase {
  func testNesting() {
    withTestingEnvironment(record: .all) {
      XCTAssertEqual(
        SnapshotEnvironment.diffTool(
          currentFilePath: "file://old.png",
          failedFilePath: "file://new.png"
        ),
        """
        @−
        "file://old.png"
        @+
        "file://new.png"

        To configure output for a custom diff tool, use 'withTestingEnvironment'. For example:

            withTestingEnvironment(diffTool: .ksdiff) {
              // ...
            }
        """
      )
      XCTAssertEqual(SnapshotEnvironment.recordMode, .all)

      withTestingEnvironment(diffTool: "ksdiff") {
        XCTAssertEqual(
          SnapshotEnvironment.diffTool(
            currentFilePath: "old.png",
            failedFilePath: "new.png"
          ),
          "ksdiff old.png new.png"
        )
        XCTAssertEqual(SnapshotEnvironment.recordMode, .all)
      }
    }
  }
}
