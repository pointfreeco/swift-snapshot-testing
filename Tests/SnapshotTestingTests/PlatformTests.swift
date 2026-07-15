import XCTest
@testable import SnapshotTesting

final class PlatformTests: XCTestCase {
  func testRawValueRoundTrip() {
    for rawValue in [
      "iOS-18.5-p3@3x",
      "iOS-26.3.1-srgb@2x",
      "tvOS-26.0-unspecified@2x",
      "macOS-15.5-unspecified@2x",
      "linux-5.0-unspecified@0x",
    ] {
      XCTAssertEqual(Platform(rawValue: rawValue)?.rawValue, rawValue)
    }
  }

  func testRawValueRejectsMalformedStrings() {
    for rawValue in [
      "",
      "iOS-18.5-p3@2",          // missing trailing x
      "iOS-18.5-p3@x",          // missing scale
      "iOS-18.5-@2x",           // missing gamut
      "iOS--p3@2x",             // missing version
      "iOS-18.5.1.2-p3@2x",     // too many version components
      "android-1.0-p3@2x",      // unknown os
      "iOS-18.5-cmyk@2x",       // unknown gamut
      "prefix-iOS-18.5-p3@2x",  // leading junk
      "iOS-18.5-p3@2x.png",     // trailing junk
      "iOS-18.5-p3@2x\n",       // trailing newline
    ] {
      XCTAssertNil(Platform(rawValue: rawValue), "expected \"\(rawValue)\" not to parse")
    }
  }

  func testVersionNormalization() {
    XCTAssertEqual(Platform.normalize(version: "18.5"), "18.5")
    XCTAssertEqual(Platform.normalize(version: "18.5.0"), "18.5")
    XCTAssertEqual(Platform.normalize(version: "26.0.0"), "26.0")
    XCTAssertEqual(Platform.normalize(version: "26.3.1"), "26.3.1")
    XCTAssertEqual(Platform.normalize(version: "18"), "18.0")

    // versions are normalized on the way into a Platform, so spellings can't diverge
    XCTAssertEqual(
      Platform(os: .iOS, version: "18.5.0", gamut: .p3, scale: 3),
      Platform(rawValue: "iOS-18.5-p3@3x")
    )
  }

  func testKnownDeviceFactories() {
    XCTAssertEqual(
      Platform.iOSSimulator(named: "iPhone 16e", version: "18.5"),
      Platform(rawValue: "iOS-18.5-p3@3x")
    )
    XCTAssertEqual(
      Platform.iOSSimulator(named: "iPhone SE (1st generation)", version: "15.0"),
      Platform(rawValue: "iOS-15.0-srgb@2x")
    )
    XCTAssertEqual(
      Platform.tvOSSimulator(named: "Apple TV 4K (3rd generation)", version: "26.0"),
      Platform(rawValue: "tvOS-26.0-unspecified@2x")
    )
    XCTAssertNil(Platform.iOSSimulator(named: "Nokia 3310", version: "1.0"))
    XCTAssertNil(Platform.iOSSimulator(named: "Apple TV 4K", version: "26.0")) // wrong os
  }

  func testPlatformOfSnapshotFile() {
    XCTAssertEqual(
      Platform.ofSnapshot(fileNamed: "testFoo-1-iOS-18.5-p3@3x.png", testName: "testFoo", identifier: "1"),
      Platform(rawValue: "iOS-18.5-p3@3x")
    )
    // testName and identifier may themselves contain "-"
    XCTAssertEqual(
      Platform.ofSnapshot(fileNamed: "testFoo-dark-mode-iOS-18.5-p3@3x.png", testName: "testFoo", identifier: "dark-mode"),
      Platform(rawValue: "iOS-18.5-p3@3x")
    )
    // wrong test name or identifier
    XCTAssertNil(Platform.ofSnapshot(fileNamed: "testFoo-1-iOS-18.5-p3@3x.png", testName: "testBar", identifier: "1"))
    XCTAssertNil(Platform.ofSnapshot(fileNamed: "testFoo-1-iOS-18.5-p3@3x.png", testName: "testFoo", identifier: "2"))
    // legacy filenames are not platform snapshots
    XCTAssertNil(Platform.ofSnapshot(fileNamed: "testFoo.1.png", testName: "testFoo", identifier: "1"))
  }

  func testCurrentPlatformRoundTrips() {
    let current = Platform()
    XCTAssertEqual(Platform(rawValue: current.rawValue), current)
  }
}

extension PlatformTests {
  static var allTests: [(String, (PlatformTests) -> () throws -> Void)] {
    return [
      ("testRawValueRoundTrip", testRawValueRoundTrip),
      ("testRawValueRejectsMalformedStrings", testRawValueRejectsMalformedStrings),
      ("testVersionNormalization", testVersionNormalization),
      ("testKnownDeviceFactories", testKnownDeviceFactories),
      ("testPlatformOfSnapshotFile", testPlatformOfSnapshotFile),
      ("testCurrentPlatformRoundTrips", testCurrentPlatformRoundTrips),
    ]
  }
}
