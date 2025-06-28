#if canImport(Testing)
import Testing
import Foundation
import InlineSnapshotTesting
import SnapshotTesting

extension BaseSuite {

    struct AssertInlineSnapshotTests {
        @Test func inlineSnapshot() async throws {
            try assertInline(of: ["Hello", "World"], as: .customDump) {
                """
                [
                  [0]: "Hello",
                  [1]: "World"
                ]
                """
            }
        }

        @Test(.record(.missing))
        func inlineSnapshotFailure() throws {
            try withKnownIssue {
                try assertInline(of: ["Hello", "World"], as: .customDump) {
                    """
                    ▿ 2 elements
                      - "Hello"

                    """
                }
            } matching: {
                $0.comments.first?.rawValue == """
                    Snapshot does not match reference. Difference: …

                      @@ −1,3 +1,4 @@
                      −▿ 2 elements
                      −  - "Hello"
                      −
                      +[
                      +  [0]: "Hello",
                      +  [1]: "World"
                      +]
                    """
            }
        }

        @Test func inlineSnapshot_NamedTrailingClosure() async throws {
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

        @Test func inlineSnapshot_Escaping() async throws {
            try assertInline(of: "Hello\"\"\"#, world", as: .lines) {
                ##"""
                Hello"""#, world
                """##
            }
        }

        @Test func customInlineSnapshot() async throws {
            try assertCustomInlineSnapshot {
                "Hello"
            } is: {
                """
                "Hello"
                """
            }
        }

        @Test func customInlineSnapshot_Multiline() async throws {
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

        @Test func customInlineSnapshot_SingleTrailingClosure() async throws {
            try assertCustomInlineSnapshot(of: { "Hello" }) {
                """
                "Hello"
                """
            }
        }

        @Test func customInlineSnapshot_MultilineSingleTrailingClosure() async throws {
            try assertCustomInlineSnapshot(
                of: { "Hello" }
            ) {
                """
                "Hello"
                """
            }
        }

        @Test func customInlineSnapshot_NoTrailingClosure() async throws {
            try assertCustomInlineSnapshot(
                of: { "Hello" },
                is: {
                    """
                    "Hello"
                    """
                }
            )
        }

        @Test func testArgumentlessInlineSnapshot() throws {
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

        @Test func multipleInlineSnapshots() async throws {
            func assertResponse(
                of url: @Sendable () -> String,
                head: (@Sendable () -> String)? = nil,
                body: (@Sendable () -> String)? = nil,
                fileID: StaticString = #fileID,
                filePath: StaticString = #filePath,
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

        @Test func asyncThrowing() async throws {
            func assertAsyncThrowingInlineSnapshot(
                of value: @Sendable () -> String,
                is expected: (@Sendable () -> String)? = nil,
                fileID: StaticString = #fileID,
                filePath: StaticString = #filePath,
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

        @Test func nestedInClosureFunction() async throws {
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

        @Test func carriageReturnInlineSnapshot() async throws {
            try assertInline(of: "This is a line\r\nAnd this is a line\r\n", as: .lines) {
                """
                This is a line\r
                And this is a line\r

                """
            }
        }

        @Test func carriageReturnRawInlineSnapshot() async throws {
            try assertInline(of: "\"\"\"#This is a line\r\nAnd this is a line\r\n", as: .lines) {
                ##"""
                """#This is a line\##r
                And this is a line\##r

                """##
            }
        }
    }
}

private func assertCustomInlineSnapshot(
    of value: @Sendable () -> String,
    is expected: (@Sendable () -> String)? = nil,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
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
