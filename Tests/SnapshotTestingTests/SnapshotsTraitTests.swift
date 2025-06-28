import SnapshotTesting
import Testing

extension BaseSuite {

    struct SnapshotsTraitTests {

        @Test(.diffTool("ksdiff"))
        func testDiffTool() {
            #expect(
                SnapshotEnvironment.current.diffTool(
                    currentFilePath: "old.png",
                    failedFilePath: "new.png"
                )
                    == "ksdiff old.png new.png"
            )
        }

        @Suite(.diffTool("ksdiff"))
        struct OverrideDiffTool {
            @Test(.diffTool("difftool"))
            func testDiffToolOverride() {
                #expect(
                    SnapshotEnvironment.current.diffTool(
                        currentFilePath: "old.png",
                        failedFilePath: "new.png"
                    )
                        == "difftool old.png new.png"
                )
            }

            @Suite(.record(.all))
            struct OverrideRecord {
                @Test
                func config() {
                    #expect(
                        SnapshotEnvironment.current.diffTool(
                            currentFilePath: "old.png",
                            failedFilePath: "new.png"
                        )
                            == "ksdiff old.png new.png"
                    )
                    #expect(SnapshotEnvironment.current.recordMode == .all)
                }

                @Suite(.record(.failed), .diffTool("diff"))
                struct OverrideDiffToolAndRecord {
                    @Test
                    func config() {
                        #expect(
                            SnapshotEnvironment.current.diffTool(
                                currentFilePath: "old.png",
                                failedFilePath: "new.png"
                            )
                                == "diff old.png new.png"
                        )
                        #expect(SnapshotEnvironment.current.recordMode == .failed)
                    }
                }
            }
        }
    }
}
