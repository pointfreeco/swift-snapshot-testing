#if compiler(>=6) && canImport(Testing)
  import Testing
  import SnapshotTesting

  @Suite(.snapshots(diffTool: "ksdiff"))
  struct SwiftTestingTests {
    @Test func testSnapshot() {
      assertSnapshot(of: ["Hello", "World"], as: .dump)
    }

    @Test func testSnapshotFailure() {
      withKnownIssue {
        assertSnapshot(of: ["Goodbye", "World"], as: .dump)
      } matching: { issue in
        issue.description.hasSuffix(
          """
          @@ −1,4 +1,4 @@
           ▿ 2 elements
          −  - "Hello"
          +  - "Goodbye"
             - "World"
          """)
      }
    }
  }
#endif
