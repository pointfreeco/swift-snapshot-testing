@_spi(Internals) @testable import SnapshotTesting
import XCTest

class WithSnapshotTestingTests: XCTestCase {
  func testNesting() {
    withSnapshotTesting(record: .all) {
      XCTAssertEqual(
        SnapshotTestingConfiguration.current?
          .diffTool?(currentFilePath: "old.png", failedFilePath: "new.png"),
        """
        @−
        "file://old.png"
        @+
        "file://new.png"

        To configure output for a custom diff tool, use 'withSnapshotTesting'. For example:

            withSnapshotTesting(diffTool: .ksdiff) {
              // ...
            }
        """
      )
      XCTAssertEqual(SnapshotTestingConfiguration.current?.record, .all)
      withSnapshotTesting(diffTool: "ksdiff") {
        XCTAssertEqual(
          SnapshotTestingConfiguration.current?
            .diffTool?(currentFilePath: "old.png", failedFilePath: "new.png"),
          "ksdiff old.png new.png"
        )
        XCTAssertEqual(SnapshotTestingConfiguration.current?.record, .all)
      }
    }
  }
}
