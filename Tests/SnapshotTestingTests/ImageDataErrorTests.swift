#if os(iOS) || os(tvOS) || os(macOS)
  import XCTest

  import zlib

  #if os(macOS)
    import AppKit
  #else
    import UIKit
  #endif

  @testable import SnapshotTesting

  #if os(macOS)
    private typealias PlatformImage = NSImage
  #else
    private typealias PlatformImage = UIImage
  #endif

  // [#707](https://github.com/pointfreeco/swift-snapshot-testing/issues/707),
  // [#1054](https://github.com/pointfreeco/swift-snapshot-testing/pull/1054): an unreadable
  // reference or unencodable snapshot crashed the test process.
  final class ImageDataErrorTests: XCTestCase {
    // The PNG signature and one stray byte.
    private static let truncatedPNG = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00])
    private let references: [(name: String, data: Data, reason: String)] = [
      ("empty", Data(), "the file is empty."),
      (
        "lfs",
        Data("version https://git-lfs.github.com/spec/v1\noid sha256:8f57\nsize 1047456\n".utf8),
        "the file is a Git LFS pointer, so its content hasn't been downloaded."
      ),
      (
        "lfs-conflict",
        Data(
          "version https://git-lfs.github.com/spec/v1\n<<<<<<< HEAD\noid sha256:8f57\n=======\noid sha256:0a2e\n>>>>>>> branch\n"
            .utf8),
        "the file is a Git LFS pointer with merge conflict markers."
      ),
      (
        // Two added pointers conflicting in diff3 style.
        "lfs-diff3-conflict",
        Data(
          "<<<<<<< HEAD\nversion https://git-lfs.github.com/spec/v1\noid sha256:8f57\n||||||| empty tree\n=======\nversion https://git-lfs.github.com/spec/v1\noid sha256:0a2e\n>>>>>>> branch\n"
            .utf8),
        "the file is a Git LFS pointer with merge conflict markers."
      ),
      (
        "truncated", ImageDataErrorTests.truncatedPNG, "PNG data are truncated after its signature."
      ),
      ("text", Data("not an image".utf8), "They start with 6e 6f 74 20 61 6e 20 69."),
    ]

    func testUnreadableReferencesReportTheirCause() throws {
      for reference in references {
        let directory = try temporaryDirectory()
        let file = URL(fileURLWithPath: directory).appendingPathComponent(
          "reference.\(reference.name).png")
        try reference.data.write(to: file)

        let failure = verifySnapshot(
          of: view(), as: .image, named: reference.name, record: .never,
          snapshotDirectory: directory, testName: "reference")

        try assertUnreadable(failure, file: file, reference: reference)
      }
    }

    // Image decoders accept these files: they ignore checksums and a missing IEND chunk, and fill
    // rows missing from a cut-short file with zeros.
    func testDamagedReferencesThatDecodersAcceptReportTheirCause() throws {
      let image = try noiseImage()
      let directory = try temporaryDirectory()
      let file = URL(fileURLWithPath: directory).appendingPathComponent("damaged.noise.png")
      _ = verifySnapshot(
        of: image, as: .image, named: "noise", record: .all, snapshotDirectory: directory,
        testName: "damaged")
      let png = try Data(contentsOf: file)
      var checksumFlipped = png
      // The last byte of the checksum of the IDAT chunk before the 12-byte IEND chunk.
      checksumFlipped[png.count - 13] ^= 0xFF
      let references: [(name: String, data: Data, reason: String)] = [
        // 60% in, inside the image data.
        ("cut", png.prefix(png.count * 3 / 5), "its IDAT chunk runs past the end of the file."),
        ("no-iend", png.dropLast(12), "truncated after its IDAT chunk."),
        ("checksum", checksumFlipped, "its IDAT chunk doesn't match its checksum."),
        // IEND overwritten with zeros, like a preallocated file that never finished writing.
        (
          "zero-filled", png.dropLast(12) + Data(count: 12),
          "the chunk header at byte \(png.count - 12) isn't valid."
        ),
      ]

      for reference in references {
        try reference.data.write(to: file)

        let failure = verifySnapshot(
          of: image, as: .image, named: "noise", record: .never, snapshotDirectory: directory,
          testName: "damaged")

        try assertUnreadable(failure, file: file, reference: reference)
      }

      // Decoders ignore bytes after IEND, so they don't make a reference unreadable.
      try (png + Data("trailing".utf8)).write(to: file)
      XCTAssertNil(
        verifySnapshot(
          of: image, as: .image, named: "noise", record: .never, snapshotDirectory: directory,
          testName: "damaged"))
    }

    func testReferenceWithIntactChunksThatCantBeDecodedSaysSo() throws {
      let directory = try temporaryDirectory()
      let file = URL(fileURLWithPath: directory).appendingPathComponent("undecodable.noise.png")
      _ = verifySnapshot(
        of: try noiseImage(), as: .image, named: "noise", record: .all,
        snapshotDirectory: directory, testName: "undecodable")
      var png = try Data(contentsOf: file)
      // A zero width with a valid checksum. IHDR's 13 data bytes start at byte 16, and its CRC, of
      // its type and data from byte 12, is at byte 29.
      png.replaceSubrange(16..<20, with: [UInt8](repeating: 0, count: 4))
      let checksum = png[12..<29].withUnsafeBytes {
        UInt32(crc32(0, $0.bindMemory(to: Bytef.self).baseAddress, 17))
      }
      png.replaceSubrange(29..<33, with: withUnsafeBytes(of: checksum.bigEndian, Array.init))
      try png.write(to: file)

      let failure = verifySnapshot(
        of: try noiseImage(), as: .image, named: "noise", record: .never,
        snapshotDirectory: directory, testName: "undecodable")

      XCTAssertTrue(
        failure?.contains("PNG data couldn't be decoded. Re-record the snapshot.") == true,
        failure ?? "nil")
    }

    func testFailedRecordModeReplacesAnUnreadableReference() throws {
      let directory = try temporaryDirectory()
      let file = URL(fileURLWithPath: directory).appendingPathComponent("reference.truncated.png")
      try Self.truncatedPNG.write(to: file)

      let failure = verifySnapshot(
        of: view(), as: .image, named: "truncated", record: .failed, snapshotDirectory: directory,
        testName: "reference")

      XCTAssertTrue(failure?.hasSuffix("A new snapshot was automatically recorded.") == true)
      XCTAssertNotNil(PlatformImage(data: try Data(contentsOf: file)))
      XCTAssertNil(
        verifySnapshot(
          of: view(), as: .image, named: "truncated", record: .never, snapshotDirectory: directory,
          testName: "reference"))
    }

    func testFailedRecordModeKeepsGitLFSPointers() throws {
      for pointer in references where pointer.name.hasPrefix("lfs") {
        let directory = try temporaryDirectory()
        let file = URL(fileURLWithPath: directory).appendingPathComponent(
          "failed.\(pointer.name).png")
        try pointer.data.write(to: file)

        let failure = verifySnapshot(
          of: view(), as: .image, named: pointer.name, record: .failed,
          snapshotDirectory: directory, testName: "failed")

        try assertUnreadable(failure, file: file, reference: pointer)
        XCTAssertEqual(
          try Data(contentsOf: file), pointer.data, "\(pointer.name): \"git lfs pull\" still works")
      }
    }

    func testGitLFSPointerIsReportedForAnyStrategy() throws {
      struct Undecodable: Error {}
      let strategy = Snapshotting<String, String>(
        pathExtension: "txt",
        diffing: .diff(toData: { Data($0.utf8) }, fromData: { _ in throw Undecodable() }) { _, _ in
          nil
        })
      let directory = try temporaryDirectory()
      let file = URL(fileURLWithPath: directory).appendingPathComponent("failed.text.txt")
      let pointer = try XCTUnwrap(references.first { $0.name == "lfs" })
      try pointer.data.write(to: file)

      let failure = try XCTUnwrap(
        verifySnapshot(
          of: "text", as: strategy, named: "text", record: .failed, snapshotDirectory: directory,
          testName: "failed"))

      XCTAssertTrue(
        failure.hasPrefix("Reference \"\(file.path)\" could not be loaded: \(pointer.reason)"),
        failure)
      XCTAssertEqual(try Data(contentsOf: file), pointer.data)
    }

    func testFailedRecordModeReportsWhyTheNewSnapshotCouldntBeRecorded() throws {
      let directory = try temporaryDirectory()
      let file = URL(fileURLWithPath: directory).appendingPathComponent("encoding.truncated.png")
      try Self.truncatedPNG.write(to: file)
      #if os(macOS)
        let (image, reason) = (NSImage(), ImageEncodingError.Reason.noImageData(size: .zero))
      #else
        let (image, reason) = (
          UIImage(ciImage: CIImage(color: .red)), ImageEncodingError.Reason.infiniteCIImage
        )
      #endif

      let failure = try XCTUnwrap(
        verifySnapshot(
          of: image, as: .image, named: "truncated", record: .failed,
          snapshotDirectory: directory, testName: "encoding"))

      let cause = try XCTUnwrap(ImageReferenceError(data: Self.truncatedPNG).errorDescription)
      let encoding = try XCTUnwrap(ImageEncodingError(reason: reason).errorDescription)
      XCTAssertTrue(
        failure.hasPrefix("Reference \"\(file.path)\" could not be loaded: \(cause)"), failure)
      XCTAssertTrue(
        failure.hasSuffix(" A new snapshot couldn't be recorded: \(encoding)"), failure)
    }

    #if os(macOS)
      func testImageWithoutImageDataReportsWhyItCantBeEncoded() throws {
        XCTAssertEqual(
          try recordFailure(NSImage()),
          ImageEncodingError(reason: .noImageData(size: .zero)).errorDescription)
      }

      func testImageLongerThanPNGAllowsReportsTheLimit() throws {
        let height = ImageEncodingError.maximumPixelsPerSide + 1
        let rep = try XCTUnwrap(
          NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: 1, pixelsHigh: height, bitsPerSample: 8,
            samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
            bytesPerRow: 4, bitsPerPixel: 32))
        let image = NSImage(size: rep.size)
        image.addRepresentation(rep)

        XCTAssertEqual(
          try recordFailure(image),
          ImageEncodingError(reason: .tooLarge(width: 1, height: height)).errorDescription)
      }

      func testInfiniteCIImageReportsWhyItCantBeEncoded() throws {
        // Sized from its representation, like UIImage(ciImage:), and without a finite
        // representation alongside it, which some macOS versions draw and encode instead.
        let representation = NSCIImageRep(ciImage: CIImage(color: .red))
        let image = NSImage(size: representation.size)
        image.addRepresentation(representation)

        XCTAssertEqual(
          try recordFailure(image),
          ImageEncodingError(reason: .infiniteCIImage).errorDescription)
      }

      func testEmptyCIImageReportsThatItHasNothingToDraw() throws {
        let image = NSImage(size: CGSize(width: 8, height: 8))
        image.addRepresentation(NSCIImageRep(ciImage: .empty()))

        XCTAssertEqual(
          try recordFailure(image),
          ImageEncodingError(reason: .noImageData(size: CGSize(width: 8, height: 8)))
            .errorDescription)
      }

      private func recordFailure(_ image: NSImage) throws -> String? {
        verifySnapshot(
          of: image, as: .image, named: "encoding", record: .all,
          snapshotDirectory: try temporaryDirectory(), testName: "image")
      }

      private func view() -> NSView {
        let view = NSView(frame: CGRect(x: 0, y: 0, width: 8, height: 8))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.red.cgColor
        return view
      }
    #else
      func testSnapshotWithoutImageDataRecordsAPlaceholder() throws {
        for (name, image) in [("zero", UIImage()), ("empty-ciimage", UIImage(ciImage: .empty()))] {
          let directory = try temporaryDirectory()

          let failure = verifySnapshot(
            of: image, as: .image, named: name, record: .all, snapshotDirectory: directory,
            testName: "encoding")

          XCTAssertTrue(failure?.hasPrefix("Record mode is on.") == true, failure ?? "nil")
          let file = URL(fileURLWithPath: directory).appendingPathComponent("encoding.\(name).png")
          let placeholder = try XCTUnwrap(UIImage(data: try Data(contentsOf: file)), name)
          XCTAssertEqual(placeholder.size.width / placeholder.size.height, 5, name)
        }
      }

      func testImageLongerThanPNGAllowsReportsTheLimit() throws {
        let height = ImageEncodingError.maximumPixelsPerSide + 1
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: height), format: format)
          .image { _ in }

        XCTAssertEqual(
          try recordFailure(image),
          ImageEncodingError(reason: .tooLarge(width: 1, height: height)).errorDescription)
      }

      func testInfiniteCIImageReportsWhyItCantBeEncoded() throws {
        XCTAssertEqual(
          try recordFailure(UIImage(ciImage: CIImage(color: .red))),
          ImageEncodingError(reason: .infiniteCIImage).errorDescription)
      }

      // Compared against a valid reference, the snapshot has no CGImage, so the difference image
      // falls back to drawing both images at its enormous size. That must not abort the process.
      func testInfiniteCIImageComparedWithAReferenceReportsWhyItCantBeEncoded() throws {
        let directory = try temporaryDirectory()
        _ = verifySnapshot(
          of: try noiseImage(), as: .image, named: "infinite", record: .all,
          snapshotDirectory: directory, testName: "comparison")
        let file = URL(fileURLWithPath: directory).appendingPathComponent("comparison.infinite.png")
        let reference = try Data(contentsOf: file)

        let failure = verifySnapshot(
          of: UIImage(ciImage: CIImage(color: .red)), as: .image, named: "infinite",
          record: .never, snapshotDirectory: directory, testName: "comparison")

        XCTAssertEqual(failure, ImageEncodingError(reason: .infiniteCIImage).errorDescription)
        XCTAssertEqual(try Data(contentsOf: file), reference)
      }

      private func recordFailure(_ image: UIImage) throws -> String? {
        verifySnapshot(
          of: image, as: .image, named: "encoding", record: .all,
          snapshotDirectory: try temporaryDirectory(), testName: "image")
      }

      private func view() -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 8))
        view.backgroundColor = .red
        return view
      }
    #endif

    /// An opaque image whose PNG data spans several IDAT chunks, like most references.
    private func noiseImage() throws -> PlatformImage {
      // A linear congruential generator (Numerical Recipes' constants), for deterministic noise.
      var state: UInt32 = 1
      let pixels = (0..<128 * 128).flatMap { _ -> [UInt8] in
        state = state &* 1_664_525 &+ 1_013_904_223
        // The top three bytes as RGB: a linear congruential generator's low bits are the least
        // random. 255 is opaque.
        return [UInt8(state >> 24), UInt8(state >> 16 & 0xFF), UInt8(state >> 8 & 0xFF), 255]
      }
      let cgImage = try XCTUnwrap(
        CGImage(
          width: 128, height: 128, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 128 * 4,
          space: try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB)),
          bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
          provider: try XCTUnwrap(CGDataProvider(data: Data(pixels) as CFData)), decode: nil,
          shouldInterpolate: false, intent: .defaultIntent))
      #if os(macOS)
        return NSImage(cgImage: cgImage, size: CGSize(width: 128, height: 128))
      #else
        return UIImage(cgImage: cgImage)
      #endif
    }

    /// Checks that a failure names the unreadable reference and its cause, and that the new snapshot
    /// was saved as an image.
    private func assertUnreadable(
      _ failure: String?, file: URL, reference: (name: String, data: Data, reason: String)
    ) throws {
      let failure = try XCTUnwrap(failure, reference.name)
      let cause = try XCTUnwrap(ImageReferenceError(data: reference.data).errorDescription)
      XCTAssertTrue(
        failure.hasPrefix("Reference \"\(file.path)\" could not be loaded: \(cause)"),
        "\(reference.name): \(failure)")
      XCTAssertTrue(failure.contains(reference.reason), "\(reference.name): \(failure)")
      // The message ends with the saved snapshot's quoted path and a period.
      let saved = failure.components(separatedBy: "The new snapshot was saved to \"").last?
        .dropLast(2)
      XCTAssertNotNil(
        saved.flatMap { PlatformImage(contentsOfFile: String($0)) }, "\(reference.name): \(failure)"
      )
    }

    private func temporaryDirectory() throws -> String {
      let directory = NSTemporaryDirectory() + "ImageDataErrorTests-" + UUID().uuidString
      try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
      addTeardownBlock { try? FileManager.default.removeItem(atPath: directory) }
      return directory
    }
  }
#endif
