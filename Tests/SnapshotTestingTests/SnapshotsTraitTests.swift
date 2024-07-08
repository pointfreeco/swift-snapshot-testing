#if compiler(>=6) && canImport(Testing)
@_spi(Experimental) import Testing
@_spi(Experimental) @_spi(Internals) import SnapshotTesting


struct SnapshotsTraitTests {
  @Test(.snapshots(diffTool: "ksdiff"))
  func testDiffTool() {
    #expect(
      SnapshotTestingConfiguration.current?
        .diffTool?(currentFilePath: "old.png", failedFilePath: "new.png")
      == "ksdiff old.png new.png"
    )
  }

  @Suite(.snapshots(diffTool: "ksdiff"))
  struct OverrideDiffTool {
    @Test(.snapshots(diffTool: "difftool"))
    func testDiffToolOverride() {
      #expect(
        SnapshotTestingConfiguration.current?
          .diffTool?(currentFilePath: "old.png", failedFilePath: "new.png")
        == "difftool old.png new.png"
      )
    }

    @Suite(.snapshots(record: .all))
    struct OverrideRecord {
      @Test
      func config() {
        #expect(
          SnapshotTestingConfiguration.current?
            .diffTool?(currentFilePath: "old.png", failedFilePath: "new.png")
          == "ksdiff old.png new.png"
        )
        #expect(SnapshotTestingConfiguration.current?.record == .all)
      }

      @Suite(.snapshots(record: .failed, diffTool: "diff"))
      struct OverrideDiffToolAndRecord {
        @Test
        func config() {
          #expect(
            SnapshotTestingConfiguration.current?
              .diffTool?(currentFilePath: "old.png", failedFilePath: "new.png")
            == "diff old.png new.png"
          )
          #expect(SnapshotTestingConfiguration.current?.record == .failed)
        }
      }
    }
  }
}
#endif
