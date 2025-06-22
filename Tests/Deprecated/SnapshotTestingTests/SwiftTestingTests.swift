#if !os(visionOS)
  #if compiler(>=6) && canImport(Testing)
    import Testing
    import SnapshotTesting

    extension BaseSuite {
      @Suite(.serialized, .snapshots(record: .missing))
      struct SwiftTestingTests {
        @Test func testSnapshot() {
          assertSnapshot(of: ["Hello", "World"], as: .dump, named: "snap")
          withKnownIssue {
            assertSnapshot(of: ["Goodbye", "World"], as: .dump, named: "snap")
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
    }
  #endif
#endif
