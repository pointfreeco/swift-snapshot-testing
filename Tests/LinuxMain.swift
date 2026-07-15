import XCTest
@testable import SnapshotTestingTests

XCTMain([
  testCase(PlatformTests.allTests),
  testCase(SnapshotTestingTests.allTests),
])
