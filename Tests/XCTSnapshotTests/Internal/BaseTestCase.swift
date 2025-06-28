@_spi(Internals) import XCTSnapshot
@preconcurrency import XCTest

class BaseTestCase: XCTestCase {

    var platform: String? {
        ""
    }

    override func invokeTest() {
        withTestingEnvironment(
            record: .failed,
            diffTool: .ksdiff,
            platform: platform
        ) {
            super.invokeTest()
        }
    }
}
