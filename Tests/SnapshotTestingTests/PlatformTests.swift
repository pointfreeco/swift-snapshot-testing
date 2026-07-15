import XCTest

@testable import SnapshotTesting

#if canImport(UIKit)
  import UIKit
#endif

final class PlatformTests: XCTestCase {
  override func tearDown() {
    supportedPlatforms = nil
    super.tearDown()
  }

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
      "iOS-18.5-p3@2",  // missing trailing x
      "iOS-18.5-p3@x",  // missing scale
      "iOS-18.5-@2x",  // missing gamut
      "iOS--p3@2x",  // missing version
      "iOS-18.5.1.2-p3@2x",  // too many version components
      "amigaOS-1.0-p3@2x",  // unknown os
      "iOS-18.5-cmyk@2x",  // unknown gamut
      "prefix-iOS-18.5-p3@2x",  // leading junk
      "iOS-18.5-p3@2x.png",  // trailing junk
      "iOS-18.5-p3@2x\n",  // trailing newline
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
    XCTAssertNil(Platform.iOSSimulator(named: "Apple TV 4K", version: "26.0"))  // wrong os
  }

  func testPlatformOfSnapshotFile() {
    XCTAssertEqual(
      Platform.ofSnapshot(
        fileNamed: "testFoo-1-iOS-18.5-p3@3x.png", testName: "testFoo", identifier: "1"),
      Platform(rawValue: "iOS-18.5-p3@3x")
    )
    // testName and identifier may themselves contain "-"
    XCTAssertEqual(
      Platform.ofSnapshot(
        fileNamed: "testFoo-dark-mode-iOS-18.5-p3@3x.png", testName: "testFoo",
        identifier: "dark-mode"),
      Platform(rawValue: "iOS-18.5-p3@3x")
    )
    // wrong test name or identifier
    XCTAssertNil(
      Platform.ofSnapshot(
        fileNamed: "testFoo-1-iOS-18.5-p3@3x.png", testName: "testBar", identifier: "1"))
    XCTAssertNil(
      Platform.ofSnapshot(
        fileNamed: "testFoo-1-iOS-18.5-p3@3x.png", testName: "testFoo", identifier: "2"))
    // legacy filenames are not platform snapshots
    XCTAssertNil(
      Platform.ofSnapshot(fileNamed: "testFoo.1.png", testName: "testFoo", identifier: "1"))
  }

  func testCurrentPlatformRoundTrips() {
    let current = Platform()
    XCTAssertEqual(Platform(rawValue: current.rawValue), current)
  }

  func testSimulatorBasedFilenames() {
    #if os(iOS) || os(tvOS)
      let snapshotDirectory =
        NSTemporaryDirectory() + "SimulatorBasedFilenames-" + UUID().uuidString
      defer { try? FileManager.default.removeItem(atPath: snapshotDirectory) }

      supportedPlatforms = [Platform()]
      let view = UIView(frame: .init(origin: .zero, size: .init(width: 10, height: 10)))
      let failure = verifySnapshot(
        of: view, as: .image, named: "reference", record: .missing,
        snapshotDirectory: snapshotDirectory)

      // the first run in an empty directory records a reference named for the current platform
      XCTAssert(failure?.contains("Automatically recorded") ?? false)
      let snapshotPath =
        snapshotDirectory + "/testSimulatorBasedFilenames-reference-\(Platform().rawValue).png"
      XCTAssert(FileManager.default.fileExists(atPath: snapshotPath))

      // and a second run compares clean against it
      XCTAssertNil(
        verifySnapshot(
          of: view, as: .image, named: "reference", record: .missing,
          snapshotDirectory: snapshotDirectory))
    #endif
  }

  func testSimulatorBasedFilenamesBlockRecording() {
    #if os(iOS) || os(tvOS)
      let fileManager = FileManager.default
      let snapshotDirectory = NSTemporaryDirectory() + "BlockRecording-" + UUID().uuidString
      try! fileManager.createDirectory(
        atPath: snapshotDirectory, withIntermediateDirectories: true)
      defer { try? fileManager.removeItem(atPath: snapshotDirectory) }

      // a reference recorded by some other, incompatible simulator (the guard never reads it)
      let otherPlatform = Platform(os: .iOS, version: "1.0", gamut: .srgb, scale: 1)
      XCTAssertNotEqual(otherPlatform, Platform())
      let otherPath =
        snapshotDirectory
        + "/testSimulatorBasedFilenamesBlockRecording-reference-\(otherPlatform.rawValue).png"
      fileManager.createFile(atPath: otherPath, contents: Data("not a real png".utf8))

      let currentPath =
        snapshotDirectory
        + "/testSimulatorBasedFilenamesBlockRecording-reference-\(Platform().rawValue).png"
      let view = UIView(frame: .init(origin: .zero, size: .init(width: 10, height: 10)))

      // do not record while the current platform is not explicitly supported…
      supportedPlatforms = []
      let failureBecauseOtherExists = verifySnapshot(
        of: view, as: .image, named: "reference", record: .missing,
        snapshotDirectory: snapshotDirectory)
      XCTAssert(failureBecauseOtherExists?.contains("incompatible simulator") ?? false)
      XCTAssert(failureBecauseOtherExists?.contains(otherPath) ?? false)
      XCTAssert(!fileManager.fileExists(atPath: currentPath))

      // …not even in record-everything mode
      let failureDespiteRecordAll = verifySnapshot(
        of: view, as: .image, named: "reference", record: .all,
        snapshotDirectory: snapshotDirectory)
      XCTAssert(failureDespiteRecordAll?.contains("incompatible simulator") ?? false)
      XCTAssert(!fileManager.fileExists(atPath: currentPath))

      // do record (despite the other-platform snapshot) once this platform is *explicitly* supported
      supportedPlatforms = [Platform()]
      let failureBecauseRecording = verifySnapshot(
        of: view, as: .image, named: "reference", record: .missing,
        snapshotDirectory: snapshotDirectory)
      XCTAssert(failureBecauseRecording?.contains("Automatically recorded") ?? false)
      XCTAssert(fileManager.fileExists(atPath: currentPath))
    #endif
  }
}
