#if !os(visionOS)
#if canImport(Testing)
  import Testing
  import InlineSnapshotTesting
  import SnapshotTestingCustomDump

  extension BaseSuite {
    struct CustomDumpSnapshotTests {
      @Test func basics() {
        struct User { let id: Int, name: String, bio: String }
        let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
        assertInlineSnapshot(of: user, as: .customDump) {
          """
          BaseSuite.CustomDumpSnapshotTests.User(
            id: 1,
            name: "Blobby",
            bio: "Blobbed around the world."
          )
          """
        }
      }
    }
  }
#endif
#endif