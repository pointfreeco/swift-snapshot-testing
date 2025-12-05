#if canImport(Testing)
  import Testing
  import Foundation
  import InlineSnapshotTesting
  import SnapshotTesting

  extension BaseSuite {
    @Suite
    struct AssertInlineSnapshotTests {
      @Test func inlineSnapshot() {
        assertInlineSnapshot(of: ["Hello", "World"], as: .dump) {
          """
          ▿ 2 elements
            - "Hello"
            - "World"

          """
        }
      }

      @Test(.snapshots(record: .missing)) func inlineSnapshotFailure() {
        withKnownIssue {
          assertInlineSnapshot(of: ["Hello", "World"], as: .dump) {
            """
            ▿ 2 elements
              - "Hello"

            """
          }
        } matching: { issue in
          issue.description.hasSuffix(
            """
            Snapshot did not match. Difference: …

              @@ −1,3 +1,4 @@
               ▿ 2 elements
                 - "Hello"
              +  - "World"
               
            """)
        }
      }

      @Test func inlineSnapshot_NamedTrailingClosure() {
        assertInlineSnapshot(
          of: ["Hello", "World"], as: .dump,
          matches: {
            """
            ▿ 2 elements
              - "Hello"
              - "World"

            """
          })
      }

      @Test func inlineSnapshot_Escaping() {
        assertInlineSnapshot(of: "Hello\"\"\"#, world", as: .lines) {
          ##"""
          Hello"""#, world
          """##
        }
      }

      @Test func customInlineSnapshot() {
        assertCustomInlineSnapshot {
          "Hello"
        } is: {
          """
          - "Hello"

          """
        }
      }

      @Test func customInlineSnapshot_Multiline() {
        assertCustomInlineSnapshot {
          """
          "Hello"
          "World"
          """
        } is: {
          #"""
          - "\"Hello\"\n\"World\""

          """#
        }
      }

      @Test func customInlineSnapshot_SingleTrailingClosure() {
        assertCustomInlineSnapshot(of: { "Hello" }) {
          """
          - "Hello"

          """
        }
      }

      @Test func customInlineSnapshot_MultilineSingleTrailingClosure() {
        assertCustomInlineSnapshot(
          of: { "Hello" }
        ) {
          """
          - "Hello"

          """
        }
      }

      @Test func customInlineSnapshot_NoTrailingClosure() {
        assertCustomInlineSnapshot(
          of: { "Hello" },
          is: {
            """
            - "Hello"

            """
          }
        )
      }

      @Test func argumentlessInlineSnapshot() {
        func assertArgumentlessInlineSnapshot(
          expected: (() -> String)? = nil,
          fileID: StaticString = #fileID,
          filePath: StaticString = #filePath,
          function: StaticString = #function,
          line: UInt = #line,
          column: UInt = #column
        ) {
          assertInlineSnapshot(
            of: "Hello",
            as: .dump,
            syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
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

        assertArgumentlessInlineSnapshot {
          """
          - "Hello"

          """
        }
      }

      @Test func multipleInlineSnapshots() {
        func assertResponse(
          of url: () -> String,
          head: (() -> String)? = nil,
          body: (() -> String)? = nil,
          fileID: StaticString = #fileID,
          filePath: StaticString = #filePath,
          function: StaticString = #function,
          line: UInt = #line,
          column: UInt = #column
        ) {
          assertInlineSnapshot(
            of: """
              HTTP/1.1 200 OK
              Content-Type: text/html; charset=utf-8
              """,
            as: .lines,
            message: "Head did not match",
            syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
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
          assertInlineSnapshot(
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
            syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
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

        assertResponse {
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
          of value: () -> String,
          is expected: (() -> String)? = nil,
          fileID: StaticString = #fileID,
          filePath: StaticString = #filePath,
          function: StaticString = #function,
          line: UInt = #line,
          column: UInt = #column
        ) async throws {
          assertInlineSnapshot(
            of: value(),
            as: .dump,
            syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
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

        try await assertAsyncThrowingInlineSnapshot {
          "Hello"
        } is: {
          """
          - "Hello"

          """
        }
      }

      @Test func nestedInClosureFunction() {
        func withDependencies(operation: () -> Void) {
          operation()
        }

        withDependencies {
          assertInlineSnapshot(of: "Hello", as: .dump) {
            """
            - "Hello"

            """
          }
        }
      }

      @Test func carriageReturnInlineSnapshot() {
        assertInlineSnapshot(of: "This is a line\r\nAnd this is a line\r\n", as: .lines) {
          """
          This is a line\r
          And this is a line\r

          """
        }
      }

      @Test func carriageReturnRawInlineSnapshot() {
        assertInlineSnapshot(of: "\"\"\"#This is a line\r\nAnd this is a line\r\n", as: .lines) {
          ##"""
          """#This is a line\##r
          And this is a line\##r

          """##
        }
      }
    }
  }

  private func assertCustomInlineSnapshot(
    of value: () -> String,
    is expected: (() -> String)? = nil,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
  ) {
    assertInlineSnapshot(
      of: value(),
      as: .dump,
      syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
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
