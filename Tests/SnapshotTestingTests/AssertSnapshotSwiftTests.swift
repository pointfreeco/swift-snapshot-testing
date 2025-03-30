#if canImport(Testing)
  import Testing
  import Foundation
  import SnapshotTesting

  extension BaseSuite {
    struct AssertSnapshotTests {
      @Test func dump() {
        struct User { let id: Int, name: String, bio: String }
        let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
        assertSnapshot(of: user, as: .dump)
      }
    }

    @MainActor
    struct MainActorTests {
      @Test func dump() {
        struct User { let id: Int, name: String, bio: String }
        let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
        assertSnapshot(of: user, as: .dump)
      }
    }
  }
#endif
