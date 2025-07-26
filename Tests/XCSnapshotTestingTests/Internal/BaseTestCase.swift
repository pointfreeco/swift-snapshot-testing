@_spi(Internals) import XCSnapshotTesting

#if canImport(XCTest)
@preconcurrency import XCTest

class BaseTestCase: XCTestCase {

    var platform: String? {
        ""
    }

    var record: RecordMode {
        .failed
    }

    override func invokeTest() {
        withTestingEnvironment(
            record: record,
            diffTool: .ksdiff,
            platform: platform
        ) {
            super.invokeTest()
        }
    }
}
#endif
