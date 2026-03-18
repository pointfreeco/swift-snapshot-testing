#if compiler(>=6) && canImport(Testing)
  import Testing
  import SnapshotTesting

  #if canImport(AppKit)
    import AppKit
  #endif

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
            """
          )
        }
      }

      #if canImport(AppKit)
        @Test(
          .enabled {
            !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW")
          }
        )
        func testImage() {
          let redPixel = NSImage(size: NSSize(width: 1, height: 1), flipped: false) { rect in
            NSColor.red.setFill()
            rect.fill()
            return true
          }
          let bluePixel = NSImage(size: NSSize(width: 1, height: 1), flipped: false) { rect in
            NSColor.blue.setFill()
            rect.fill()
            return true
          }
          assertSnapshot(of: redPixel, as: .image, named: "pixel")
          withKnownIssue {
            assertSnapshot(of: bluePixel, as: .image, named: "pixel")
          } matching: { issue in
            issue.description.hasSuffix(
              "Newly-taken snapshot does not match reference."
            )
          }
        }
      #endif
    }
  }
#endif
