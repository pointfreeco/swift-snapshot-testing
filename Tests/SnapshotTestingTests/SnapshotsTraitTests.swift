#if compiler(>=6) && canImport(Testing)
  import Testing
  @_spi(Internals) import SnapshotTesting

  extension BaseSuite {
    struct SnapshotsTraitTests {
      @Test(.snapshots(diffTool: "ksdiff"))
      func testDiffTool() {
        #expect(
          _diffTool(currentFilePath: "old.png", failedFilePath: "new.png")
            == "ksdiff old.png new.png"
        )
      }

      @Test(.snapshots(imagePixelFormat: .displayP3))
      func testImagePixelFormat() {
        #expect(_imagePixelFormat == .displayP3)
        #if compiler(>=6.1)
          #expect(SnapshotTestingConfiguration.current?.imagePixelFormat == .displayP3)
        #endif
      }

      @Test(.snapshots(imagePixelFormat: .displayP3))
      func testImagePixelFormatReadsTraitsWithoutTaskLocal() {
        // Toolchains without TestScoping never bind the task local; '_imagePixelFormat' then scans
        // the current test's traits.
        SnapshotTestingConfiguration.$current.withValue(nil) {
          #expect(_imagePixelFormat == .displayP3)
        }
      }

      @Suite(.snapshots(imagePixelFormat: .displayP3))
      struct OverrideImagePixelFormat {
        @Test(.snapshots(record: .all))
        func inheritsImagePixelFormat() {
          #expect(_imagePixelFormat == .displayP3)
          SnapshotTestingConfiguration.$current.withValue(nil) {
            #expect(_imagePixelFormat == .displayP3)
          }
        }

        @Test(.snapshots(imagePixelFormat: .displayP3(bitDepth: .sixteen)))
        func overridesImagePixelFormat() {
          #expect(_imagePixelFormat == .displayP3(bitDepth: .sixteen))
          SnapshotTestingConfiguration.$current.withValue(nil) {
            #expect(_imagePixelFormat == .displayP3(bitDepth: .sixteen))
          }
        }
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
  }
#endif
