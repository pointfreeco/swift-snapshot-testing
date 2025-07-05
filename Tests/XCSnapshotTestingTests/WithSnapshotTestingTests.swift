@_spi(Internals) @testable import XCSnapshotTesting

#if canImport(XCTest)
import XCTest

class WithSnapshotTestingTests: XCTestCase {
    func testNesting() {
        withTestingEnvironment(record: .all) {
            XCTAssertEqual(
                SnapshotEnvironment.current.diffTool(
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
            XCTAssertEqual(SnapshotEnvironment.current.recordMode, .all)

            withTestingEnvironment(diffTool: "ksdiff") {
                XCTAssertEqual(
                    SnapshotEnvironment.current.diffTool(
                        currentFilePath: "old.png",
                        failedFilePath: "new.png"
                    ),
                    "ksdiff old.png new.png"
                )
                XCTAssertEqual(SnapshotEnvironment.current.recordMode, .all)
            }
        }
    }
}
#endif
