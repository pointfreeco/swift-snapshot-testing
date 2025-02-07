#if compiler(>=6) && canImport(Testing)
  import Testing
  @_spi(Internals) import SnapshotTesting

  struct SnapshotsTraitTests {
    @Test(.snapshots(diffTool: "ksdiff"))
    func testDiffTool() {
      #expect(
        _diffTool(currentFilePath: "old.png", failedFilePath: "new.png")
          == "ksdiff old.png new.png"
      )
    }

    @Suite(.snapshots(diffTool: "ksdiff"))
    struct OverrideDiffTool {
      @Test(.snapshots(diffTool: "difftool"))
      func testDiffToolOverride() {
        #expect(
          _diffTool(currentFilePath: "old.png", failedFilePath: "new.png")
            == "difftool old.png new.png"
        )
      }

      @Suite(.snapshots(record: .all))
      struct OverrideRecord {
        @Test
        func config() {
          #expect(
            _diffTool(currentFilePath: "old.png", failedFilePath: "new.png")
              == "ksdiff old.png new.png"
          )
          #expect(_record == .all)
        }

        @Suite(.snapshots(record: .failed, diffTool: "diff"))
        struct OverrideDiffToolAndRecord {
          @Test
          func config() {
            #expect(
              _diffTool(currentFilePath: "old.png", failedFilePath: "new.png")
                == "diff old.png new.png"
            )
            #expect(_record == .failed)
          }
        }
      }
    }
  }
#endif
