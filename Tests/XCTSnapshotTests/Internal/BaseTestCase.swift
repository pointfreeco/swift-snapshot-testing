@_spi(Internals) import XCTSnapshot
import XCTest

@MainActor
class BaseTestCase: XCTestCase, Sendable {

    @MainActor
    var platform: String? {
        ""
    }

    override func invokeTest() {
        withTestingEnvironment(
            record: .failed,
            diffTool: .ksdiff,
            platform: performOnMainThread {
                self.platform
            }
        ) {
            super.invokeTest()
        }
    }
}
