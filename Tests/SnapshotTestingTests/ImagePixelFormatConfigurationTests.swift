import XCTest

@_spi(Internals) @testable import SnapshotTesting

final class ImagePixelFormatConfigurationTests: XCTestCase {
  func testWithSnapshotTestingBindsInheritsAndOverridesImagePixelFormat() {
    XCTAssertNil(_imagePixelFormat)
    withSnapshotTesting(imagePixelFormat: .displayP3) {
      XCTAssertEqual(_imagePixelFormat, .displayP3)
      // verifySnapshot rebinds the configuration to resolve `record`; the format must survive it.
      withSnapshotTesting(record: .missing) {
        XCTAssertEqual(_imagePixelFormat, .displayP3)
      }
      withSnapshotTesting(imagePixelFormat: .displayP3(bitDepth: .sixteen)) {
        XCTAssertEqual(_imagePixelFormat, .displayP3(bitDepth: .sixteen))
        withSnapshotTesting(imagePixelFormat: .automatic) {
          XCTAssertEqual(_imagePixelFormat, .automatic)
        }
      }
    }
    XCTAssertNil(_imagePixelFormat)
  }

  func testAsyncWithSnapshotTestingBindsImagePixelFormat() async {
    await withSnapshotTesting(imagePixelFormat: .displayP3(bitDepth: .sixteen)) {
      await Task.yield()
      XCTAssertEqual(_imagePixelFormat, .displayP3(bitDepth: .sixteen))
      await withSnapshotTesting(record: .missing) {
        await Task.yield()
        XCTAssertEqual(_imagePixelFormat, .displayP3(bitDepth: .sixteen))
      }
    }
  }

  func testDisplayP3DefaultsToEightBits() {
    XCTAssertEqual(
      SnapshotTestingConfiguration.ImagePixelFormat.displayP3, .displayP3(bitDepth: .eight))
    XCTAssertNotEqual(
      SnapshotTestingConfiguration.ImagePixelFormat.displayP3, .displayP3(bitDepth: .sixteen))
    XCTAssertNotEqual(SnapshotTestingConfiguration.ImagePixelFormat.displayP3, .automatic)
    XCTAssertNotEqual(SnapshotTestingConfiguration.ImagePixelFormat.sRGB, .automatic)
    XCTAssertNotEqual(SnapshotTestingConfiguration.ImagePixelFormat.sRGB, .displayP3)
    XCTAssertEqual(SnapshotTestingConfiguration.ImagePixelFormat.sRGB, .sRGB(bitDepth: .eight))
    XCTAssertNotEqual(SnapshotTestingConfiguration.ImagePixelFormat.sRGB, .sRGB(bitDepth: .sixteen))
  }

  func testPreviousPublicShapesRemainReferenceable() async throws {
    // Unapplied references to rethrows functions are typed as throwing.
    let configure:
      (
        SnapshotTestingConfiguration.Record?, SnapshotTestingConfiguration.DiffTool?,
        () throws -> Void
      ) throws -> Void = withSnapshotTesting(record:diffTool:operation:)
    try configure(nil, nil) {}
    let configureAsync:
      (
        SnapshotTestingConfiguration.Record?, SnapshotTestingConfiguration.DiffTool?,
        () async throws -> Void
      ) async throws -> Void = withSnapshotTesting(record:diffTool:operation:)
    try await configureAsync(nil, nil) {}
    let configuration = SnapshotTestingConfiguration(record: .all, diffTool: nil)
    XCTAssertNil(configuration.imagePixelFormat)
    #if canImport(Testing)
      _ =
        _SnapshotsTestTrait.snapshots(record:diffTool:)
        as (
          SnapshotTestingConfiguration.Record?, SnapshotTestingConfiguration.DiffTool?
        ) -> _SnapshotsTestTrait
    #endif
  }
}
