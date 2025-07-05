import Foundation
import SnapshotTesting

#if canImport(XCTest)
import XCTest

@testable import InlineSnapshotTesting

final class InlineSnapshotTestingTests: BaseTestCase {
    func testInlineSnapshot() throws {
        try assertInline(of: ["Hello", "World"], as: .customDump) {
            """
            [
              [0]: "Hello",
              [1]: "World"
            ]
            """
        }
    }

    func testInlineSnapshot_NamedTrailingClosure() throws {
        try assertInline(
            of: ["Hello", "World"],
            as: .customDump,
            matches: {
                """
                [
                  [0]: "Hello",
                  [1]: "World"
                ]
                """
            }
        )
    }

    func testInlineSnapshot_Escaping() throws {
        try assertInline(of: "Hello\"\"\"#, world", as: .lines) {
            ##"""
            Hello"""#, world
            """##
        }
    }

    func testCustomInlineSnapshot() throws {
        try assertCustomInlineSnapshot {
            "Hello"
        } is: {
            """
            "Hello"
            """
        }
    }

    func testCustomInlineSnapshot_Multiline() throws {
        try assertCustomInlineSnapshot {
            """
            "Hello"
            "World"
            """
        } is: {
            #"""
            """
            "Hello"
            "World"
            """
            """#
        }
    }

    func testCustomInlineSnapshot_SingleTrailingClosure() throws {
        try assertCustomInlineSnapshot(of: { "Hello" }) {
            """
            "Hello"
            """
        }
    }

    func testCustomInlineSnapshot_MultilineSingleTrailingClosure() throws {
        try assertCustomInlineSnapshot(
            of: { "Hello" }
        ) {
            """
            "Hello"
            """
        }
    }

    func testCustomInlineSnapshot_NoTrailingClosure() throws {
        try assertCustomInlineSnapshot(
            of: { "Hello" },
            is: {
                """
                "Hello"
                """
            }
        )
    }

    func testArgumentlessInlineSnapshot() throws {
        func assertArgumentlessInlineSnapshot(
            expected: (@Sendable () -> String)? = nil,
            fileID: StaticString = #fileID,
            file filePath: StaticString = #filePath,
            function: StaticString = #function,
            line: UInt = #line,
            column: UInt = #column
        ) throws {
            try assertInline(
                of: "Hello",
                as: .customDump,
                closureDescriptor: SnapshotClosureDescriptor(),
                matches: expected,
                fileID: fileID,
                file: filePath,
                function: function,
                line: line,
                column: column
            )
        }

        try assertArgumentlessInlineSnapshot {
            """
            "Hello"
            """
        }
    }

    func testMultipleInlineSnapshots() throws {
        func assertResponse(
            of url: @Sendable () -> String,
            head: (@Sendable () -> String)? = nil,
            body: (@Sendable () -> String)? = nil,
            fileID: StaticString = #fileID,
            file filePath: StaticString = #filePath,
            function: StaticString = #function,
            line: UInt = #line,
            column: UInt = #column
        ) throws {
            try assertInline(
                of: """
                    HTTP/1.1 200 OK
                    Content-Type: text/html; charset=utf-8
                    """,
                as: .lines,
                message: "Head did not match",
                name: "head",
                closureDescriptor: SnapshotClosureDescriptor(
                    trailingClosureLabel: "head",
                    trailingClosureOffset: 1
                ),
                matches: head,
                fileID: fileID,
                file: filePath,
                function: function,
                line: line,
                column: column
            )
            try assertInline(
                of: """
                    <!doctype html>
                    <html lang="en">
                    <head>
                      <meta charset="utf-8">
                      <title>Point-Free</title>
                      <link rel="stylesheet" href="style.css">
                    </head>
                    <body>
                      <p>What's the point?</p>
                    </body>
                    </html>
                    """,
                as: .lines,
                message: "Body did not match",
                name: "body",
                closureDescriptor: SnapshotClosureDescriptor(
                    trailingClosureLabel: "body",
                    trailingClosureOffset: 2
                ),
                matches: body,
                fileID: fileID,
                file: filePath,
                function: function,
                line: line,
                column: column
            )
        }

        try assertResponse {
            """
            https://www.pointfree.co/
            """
        } head: {
            """
            HTTP/1.1 200 OK
            Content-Type: text/html; charset=utf-8
            """
        } body: {
            """
            <!doctype html>
            <html lang="en">
            <head>
              <meta charset="utf-8">
              <title>Point-Free</title>
              <link rel="stylesheet" href="style.css">
            </head>
            <body>
              <p>What's the point?</p>
            </body>
            </html>
            """
        }
    }

    func testAsyncThrowing() throws {
        func assertAsyncThrowingInlineSnapshot(
            of value: @Sendable () -> String,
            is expected: (@Sendable () -> String)? = nil,
            fileID: StaticString = #fileID,
            file filePath: StaticString = #filePath,
            function: StaticString = #function,
            line: UInt = #line,
            column: UInt = #column
        ) throws {
            try assertInline(
                of: value(),
                as: .customDump,
                closureDescriptor: SnapshotClosureDescriptor(
                    trailingClosureLabel: "is",
                    trailingClosureOffset: 1
                ),
                matches: expected,
                fileID: fileID,
                file: filePath,
                function: function,
                line: line,
                column: column
            )
        }

        try assertAsyncThrowingInlineSnapshot {
            "Hello"
        } is: {
            """
            "Hello"
            """
        }
    }

    func testNestedInClosureFunction() throws {
        func withDependencies(operation: @Sendable () throws -> Void) rethrows {
            try operation()
        }

        try withDependencies {
            try assertInline(of: "Hello", as: .customDump) {
                """
                "Hello"
                """
            }
        }
    }

    func testCarriageReturnInlineSnapshot() throws {
        try assertInline(of: "This is a line\r\nAnd this is a line\r\n", as: .lines) {
            """
            This is a line\r
            And this is a line\r

            """
        }
    }

    func testCarriageReturnRawInlineSnapshot() throws {
        try assertInline(of: "\"\"\"#This is a line\r\nAnd this is a line\r\n", as: .lines) {
            ##"""
            """#This is a line\##r
            And this is a line\##r

            """##
        }
    }

    #if canImport(Darwin)
    func testRecordFailed_IncorrectExpectation() throws {
        try XCTExpectFailure {
            try withTestingEnvironment(record: .never) {
                try assertInline(of: 42, as: .json) {
                    """
                    4
                    """
                }
            }
        } issueMatcher: {
            $0.compactDescription == """
                failed - Snapshot does not match reference. Difference: …

                  @@ −1,1 +1,1 @@
                  −4
                  +42
                """
        }

        let records = InlineSnapshotManager.current.records(for: #filePath)

        XCTAssertTrue(records.contains { $0.function == #function && !$0.wasRecording })
    }
    #endif

    #if canImport(Darwin)
    func testRecordFailed_MissingExpectation() throws {
        try XCTExpectFailure {
            try withTestingEnvironment(record: .failed) {
                try assertInline(of: 42, as: .json)
            }
        } issueMatcher: {
            $0.compactDescription == """
                failed - No reference was found on disk. New snapshot was not recorded because recording is disabled
                """
        }

        let records = InlineSnapshotManager.current.records(for: #filePath)

        XCTAssertTrue(records.contains { $0.function == #function && !$0.wasRecording })
    }
    #endif
}

private func assertCustomInlineSnapshot(
    of value: @Sendable () -> String,
    is expected: (@Sendable () -> String)? = nil,
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
) throws {
    try assertInline(
        of: value(),
        as: .customDump,
        closureDescriptor: SnapshotClosureDescriptor(
            trailingClosureLabel: "is",
            trailingClosureOffset: 1
        ),
        matches: expected,
        fileID: fileID,
        file: filePath,
        function: function,
        line: line,
        column: column
    )
}
#endif
