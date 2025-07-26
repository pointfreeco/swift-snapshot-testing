#if !os(visionOS)
import SnapshotTesting
import XCTest

@available(*, deprecated)
class BaseTestCase: XCTestCase {
    override func invokeTest() {
        withSnapshotTesting(
            record: .failed,
            diffTool: .ksdiff
        ) {
            super.invokeTest()
        }
    }
}
#endif
