import SnapshotTesting

#if canImport(XCTest)
import XCTest

class BaseTestCase: XCTestCase {
    override func invokeTest() {
        withTestingEnvironment(
            record: .failed,
            diffTool: .ksdiff
        ) {
            super.invokeTest()
        }
    }
}
#endif
