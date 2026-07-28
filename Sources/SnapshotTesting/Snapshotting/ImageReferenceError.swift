#if os(iOS) || os(tvOS) || os(macOS)
  import Foundation

  #if canImport(zlib)
    import zlib
  #endif

  /// A reference file whose data isn't a readable image, described so the cause can be fixed.
  struct ImageReferenceError: LocalizedError {
    let data: Data

    /// Throws when PNG data is cut short or fails a chunk checksum. Image decoders accept such
    /// files: they ignore checksums and a missing IEND chunk, and fill rows missing from a
    /// cut-short file with zeros.
    static func validate(_ data: Data) throws {
      if data.starts(with: pngSignature), pngProblem(in: data) != nil {
        throw ImageReferenceError(data: data)
      }
    }

    var errorDescription: String? {
      // Conflict markers in a text file are near its start, so only that much is decoded.
      let text = String(decoding: data.prefix(512), as: UTF8.self)
      let hasConflictMarkers = text.contains("<<<<<<<") || text.contains(">>>>>>>")
      if data.isEmpty {
        return "the file is empty."
      }
      if let gitLFSPointer = gitLFSPointerDescription(data) {
        return gitLFSPointer
      }
      if hasConflictMarkers {
        return
          "the file contains merge conflict markers. Resolve the conflict or re-record the snapshot."
      }
      if data.starts(with: pngSignature) {
        guard let problem = pngProblem(in: data) else {
          return
            "the file's \(data.count) bytes of PNG data couldn't be decoded. Re-record the snapshot."
        }
        return
          "the file's \(data.count) bytes of PNG data are \(problem). Check out or download the file again, or re-record the snapshot."
      }
      let start = data.prefix(8).map { String(format: "%02x", $0) }.joined(separator: " ")
      return "the file's \(data.count) bytes aren't image data. They start with \(start)."
    }
  }

  // "\u{89}PNG\r\n\u{1A}\n", the 8 bytes every PNG file starts with.
  private let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]

  /// Describes the first PNG chunk that is cut short or fails its checksum, or returns nil when
  /// every chunk up to IEND is intact. Bytes after IEND are ignored, as decoders ignore them.
  private func pngProblem(in data: Data) -> String? {
    data.withUnsafeBytes { bytes in
      // PNG integers are big-endian.
      func uint32(at offset: Int) -> UInt32 {
        bytes[offset..<offset + 4].reduce(0) { $0 << 8 | UInt32($1) }
      }
      // Each chunk is a 4-byte big-endian length, a 4-byte type, the data, then a 4-byte CRC of the
      // type and data.
      var offset = pngSignature.count
      var previousType = "signature"
      while offset + 8 <= bytes.count {
        let length = Int(uint32(at: offset))
        let typeBytes = bytes[offset + 4..<offset + 8]
        // Chunk types are four ASCII letters (0x41-0x5A is A-Z, 0x61-0x7A is a-z) and lengths are
        // at most 2^31 - 1, so anything else is damage, such as a zero-filled tail, and isn't
        // quoted in the message.
        guard
          length <= 0x7FFF_FFFF,
          typeBytes.allSatisfy({ (0x41...0x5A).contains($0) || (0x61...0x7A).contains($0) })
        else {
          return "corrupt: the chunk header at byte \(offset) isn't valid"
        }
        let type = String(decoding: typeBytes, as: UTF8.self)
        let end = offset + 12 + length
        // A damaged length also runs past the end, so this can't tell truncation from corruption.
        guard end <= bytes.count else {
          return "truncated or corrupt: its \(type) chunk runs past the end of the file"
        }
        #if canImport(zlib)
          let checksum = crc32(
            0, bytes.baseAddress?.advanced(by: offset + 4).assumingMemoryBound(to: Bytef.self),
            uInt(length + 4))
          guard checksum == uint32(at: end - 4) else {
            return "corrupt: its \(type) chunk doesn't match its checksum"
          }
        #endif
        if type == "IEND" {
          return nil
        }
        offset = end
        previousType = "\(type) chunk"
      }
      return "truncated after its \(previousType)"
    }
  }
#endif
