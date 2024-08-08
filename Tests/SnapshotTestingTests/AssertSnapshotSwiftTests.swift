#if canImport(Testing)
  import Testing
  import Foundation
  @_spi(Experimental) import SnapshotTesting

  @Suite(
    .snapshots(
      record: .missing
    )
  )
  struct AssertSnapshotTests {
    @Test func dump() {
      struct User { let id: Int, name: String, bio: String }
      let user = User(id: 1, name: "Blobby", bio: "Blobbed around the world.")
      assertSnapshot(of: user, as: .dump)
    }
  }
#endif
