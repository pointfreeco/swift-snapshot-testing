#if canImport(Testing)
import Testing
import InlineSnapshotTesting
import SnapshotTestingCustomDump

extension BaseSuite {
    struct CustomDumpSnapshotTests {
        @Test func basics() throws {
            struct User { let id: Int, name: String, bio: String }
            let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
            try assertInline(of: user, as: .customDump) {
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
