import Foundation
import SnapshotTesting
import Testing

extension BaseSuite {

    final class RecordTests {

        let fileURL: URL = {
            let fileURL = URL(fileURLWithPath: #filePath)
                .deletingPathExtension()

            return
                fileURL
                .deletingLastPathComponent()
                .appendingPathComponent("__Snapshots__")
                .appendingPathComponent(fileURL.lastPathComponent)
        }()

        #if canImport(Darwin)
        func recordNever() async throws {
            try withKnownSnapshotURL { snapshotURL in
                try withKnownIssue {
                    try withTestingEnvironment(record: .never) {
                        try assert(of: 42, as: .json)
                    }
                } matching: {
                    $0.comments.first?.rawValue ?? "" == """
                        No reference was found on disk. New snapshot was not recorded because recording is disabled
                        """
                }

                #expect(!FileManager.default.fileExists(atPath: snapshotURL.path))
            }
        }
        #endif

        #if canImport(Darwin)
        @Test
        func recordMissing() async throws {
            try withKnownSnapshotURL { snapshotURL in
                try withKnownIssue {
                    try withTestingEnvironment(record: .missing) {
                        try assert(of: 42, as: .json)
                    }
                } matching: {
                    ($0.comments.first?.rawValue ?? "").hasPrefix(
                        """
                        No reference was found on disk. Automatically recorded snapshot: …

                        open "\(snapshotURL.absoluteString)"

                        Re-run "\(#function)" to assert against the newly-recorded snapshot.
                        """
                    )
                }

                try #expect(String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self) == "42")
            }
        }
        #endif

        #if canImport(Darwin)
        @Test
        func recordMissing_ExistingFile() async throws {
            try withKnownSnapshotURL { snapshotURL in
                try Data("999".utf8).write(to: snapshotURL)

                try withKnownIssue {
                    try withTestingEnvironment(record: .missing) {
                        try assert(of: 42, as: .json)
                    }
                } matching: {
                    ($0.comments.first?.rawValue ?? "").hasPrefix(
                        """
                        Snapshot "\(#function)" does not match reference.

                        ksdiff "\(snapshotURL.absoluteString)"
                        """
                    )
                }

                try #expect(String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self) == "999")
            }
        }
        #endif

        #if canImport(Darwin)
        @Test
        func recordAll_Fresh() async throws {
            try withKnownSnapshotURL { snapshotURL in
                try withKnownIssue {
                    try withTestingEnvironment(record: .all) {
                        try assert(of: 42, as: .json)
                    }
                } matching: {
                    ($0.comments.first?.rawValue ?? "").hasPrefix(
                        """
                        Record mode is on. Automatically recorded snapshot: …

                        open "\(snapshotURL.absoluteString)"
                        """
                    )
                }

                try #expect(String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self) == "42")
            }
        }
        #endif

        #if canImport(Darwin)
        @Test
        func recordAll_Overwrite() async throws {
            try withKnownSnapshotURL { snapshotURL in
                try Data("999".utf8).write(to: snapshotURL)

                try withKnownIssue {
                    try withTestingEnvironment(record: .all) {
                        try assert(of: 42, as: .json)
                    }
                } matching: {
                    ($0.comments.first?.rawValue ?? "").hasPrefix(
                        """
                        Record mode is on. Automatically recorded snapshot: …

                        open "\(snapshotURL.absoluteString)"
                        """
                    )
                }

                try #expect(String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self) == "42")
            }
        }
        #endif

        #if canImport(Darwin)
        @Test
        func recordFailed_WhenFailure() async throws {
            try withKnownSnapshotURL { snapshotURL in
                try Data("999".utf8).write(to: snapshotURL)

                try withKnownIssue {
                    try withTestingEnvironment(record: .failed) {
                        try assert(of: 42, as: .json)
                    }
                } matching: {
                    ($0.comments.first?.rawValue ?? "").hasPrefix(
                        """
                        Snapshot "\(#function)" does not match reference. A new snapshot was automatically recorded.

                        open "\(snapshotURL.absoluteString)"
                        """
                    )
                }

                try #expect(String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self) == "42")
            }
        }
        #endif

        @Test
        func recordFailed_NoFailure() async throws {
            try withKnownSnapshotURL { snapshotURL in
                #if os(Android)
                throw XCTSkip("cannot save next to file on Android")
                #endif
                try Data("42".utf8).write(to: snapshotURL)
                let modifiedDate =
                    try FileManager.default.attributesOfItem(
                        atPath: snapshotURL.path
                    )[FileAttributeKey.modificationDate] as! Date

                try withTestingEnvironment(record: .missing) {
                    try assert(of: 42, as: .json)
                }

                try #expect(String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self) == "42")

                try #expect(
                    FileManager.default.attributesOfItem(
                        atPath: snapshotURL.path
                    )[FileAttributeKey.modificationDate] as! Date == modifiedDate
                )
            }
        }

        #if canImport(Darwin)
        @Test
        func recordFailed_MissingFile() async throws {
            try withKnownSnapshotURL { snapshotURL in
                try withKnownIssue {
                    try withTestingEnvironment(record: .missing) {
                        try assert(of: 42, as: .json)
                    }
                } matching: {
                    ($0.comments.first?.rawValue ?? "").hasPrefix(
                        """
                        No reference was found on disk. Automatically recorded snapshot: …

                        open "\(snapshotURL.absoluteString)"
                        """
                    )
                }

                try #expect(String(decoding: Data(contentsOf: snapshotURL), as: UTF8.self) == "42")
            }
        }
        #endif
    }
}

extension BaseSuite.RecordTests {

    func withKnownSnapshotURL(
        _ testName: String = #function,
        body: @escaping @Sendable (URL) throws -> Void
    ) rethrows {
        let snapshotURL = snapshotURL(testName: testName)
        try body(snapshotURL)
        try? FileManager.default.removeItem(at: snapshotURL)
    }

    private func snapshotURL(
        testName: String
    ) -> URL {
        let testName = String(
            testName
                .split(separator: " ")
                .flatMap { String($0).split(separator: ".") }
                .last!
                .prefix(while: { $0 != "]" })
        )

        var snapshotURL = fileURL
        let platform = SnapshotEnvironment.current.platform

        if !platform.isEmpty {
            snapshotURL.appendPathComponent(platform)
        }

        snapshotURL.appendPathComponent("\(sanitizePathComponent(testName)).1.json")

        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: snapshotURL)
            return snapshotURL
        }

        try? FileManager.default.createDirectory(
            at: fileURL,
            withIntermediateDirectories: true
        )

        return snapshotURL
    }

    private func sanitizePathComponent(_ path: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
            .union(.newlines)
            .union(.illegalCharacters)
            .union(.controlCharacters)

        return
            path
            .replacingOccurrences(of: "()", with: "")
            .components(separatedBy: invalidCharacters)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .joined(separator: "")
    }
}
