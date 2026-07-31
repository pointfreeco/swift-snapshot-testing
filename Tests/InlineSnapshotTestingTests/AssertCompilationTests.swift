#if canImport(SwiftSyntax509) && canImport(Testing) && (os(macOS) || os(Linux) || os(Windows))
  import Foundation
  import InlineSnapshotTesting
  import Testing

  extension BaseSuite {
    @Suite struct AssertCompilationTests {
      @Test func compilationError() {
        assertCompilation {
          """
          let x = 1
          let y = x + "!"
          """
        } diagnostics: {
          """
          let y = x + "!"
                    ˄
                    ╰─ error: binary operator '+' cannot be applied to operands of type 'Int' and 'String'
                    ╰─ note: overloads for '+' exist with these partially matching parameter lists: (Int, Int), (String, String)
          """
        }
      }

      @Test func cleanCompilation() {
        assertCompilation {
          """
          let x = 1
          let y = x + 1
          _ = y
          """
        }
      }

      @Test func flags_Swift5LanguageMode() {
        assertCompilation(flags: [.languageMode(.v5)]) {
          """
          class Counter {}
          enum Sharing { static var counter = Counter() }
          """
        }
      }

      @Test func flags_Swift6LanguageMode() {
        assertCompilation(flags: [.languageMode(.v6)]) {
          """
          class Counter {}
          enum Sharing { static var counter = Counter() }
          """
        } diagnostics: {
          """
          enum Sharing { static var counter = Counter() }
                                    ˄
                                    ╰─ error: static property 'counter' is not concurrency-safe because it is nonisolated global shared mutable state [#MutableGlobalVariable]
                                    ╰─ note: convert 'counter' to a 'let' constant to make 'Sendable' shared state immutable
                                    ╰─ note: add '@MainActor' to make static property 'counter' part of global actor 'MainActor'
                                    ╰─ note: disable concurrency-safety checks if accesses are protected by an external synchronization mechanism
          """
        }
      }

      @Test func defaultMainActorIsolation_SendableClass() {
        assertCompilation(
          flags: [.languageMode(.v6), .defaultIsolation(.mainActor)]
        ) {
          """
          class Model {
            var count = 0
          }
          func send(_ value: some Sendable) {}
          send(Model())
          """
        }
      }

      @Test func nonisolatedByDefault_SendableClass() {
        assertCompilation(flags: [.languageMode(.v6)]) {
          """
          class Model {
            var count = 0
          }
          func send(_ value: some Sendable) {}
          send(Model())
          """
        } diagnostics: {
          """
          send(Model())
          ˄
          ╰─ error: type 'Model' does not conform to the 'Sendable' protocol
          class Model {
                ˄
                ╰─ note: class 'Model' does not conform to the 'Sendable' protocol
          """
        }
      }

      #if os(macOS) || os(Linux)
        // NB: In Swift 6.2 a soundness bug allows a non-Sendable value to escape a 'Mutex' by
        //     returning it from 'withLock'. On 'main' (as of the 2026-06-24 snapshot) this is
        //     diagnosed, as a warning for source compatibility.
        @Test(.enabled(if: isSwiftlyInstalled && hasSwift62SDK))
        func mutexEscape_Swift62() {
          assertCompilation(
            compiler: .swiftly("6.2.0", sdk: URL(fileURLWithPath: swift62SDKPath)),
            flags: [.languageMode(.v6)]
          ) {
            """
            import Synchronization
            final class NS { var value = 0 }
            let shared = Mutex(NS())
            nonisolated func escape() -> NS {
              shared.withLock { $0 }
            }
            """
          }
        }

        @Test(.enabled(if: isSwiftlyInstalled))
        func mutexEscape_MainSnapshot() {
          assertCompilation(
            compiler: .swiftly("main-snapshot-2026-06-24"),
            flags: [.languageMode(.v6)]
          ) {
            """
            import Synchronization
            final class NS { var value = 0 }
            let shared = Mutex(NS())
            nonisolated func escape() -> NS {
              shared.withLock { $0 }
            }
            """
          } diagnostics: {
            """
              shared.withLock { $0 }
                                ˄
                                ╰─ warning: 'inout sending' parameter '$0' cannot be returned; this will be an error in a future Swift language mode [#RegionIsolation]
                                ╰─ note: returning 'inout sending' parameter '$0' risks concurrent access as caller assumes '$0' and result can be sent to different isolation domains
            """
          }
        }

        @Test(.enabled(if: isSwiftlyInstalled)) func swiftlyToolchain() {
          assertCompilation(compiler: .swiftly("6.2.0")) {
            """
            let x = 1
            let y = x + "!"
            """
          } diagnostics: {
            """
            let y = x + "!"
                      ˄
                      ╰─ error: binary operator '+' cannot be applied to operands of type 'Int' and 'String'
                      ╰─ note: overloads for '+' exist with these partially matching parameter lists: (Int, Int), (String, String)
            """
          }
        }
      #endif

      @Test func warning() {
        assertCompilation {
          """
          func greet() {
            let name = "Blob"
          }
          """
        } diagnostics: {
          """
            let name = "Blob"
                ˄
                ╰─ warning: initialization of immutable value 'name' was never used; consider replacing with assignment to '_' or removing it [#NoUsage]
          """
        }
      }

      @Test func importPackageModule() {
        assertCompilation {
          """
          import SnapshotTesting
          SnapshotTesting.diffTool = .ksdiff
          """
        } diagnostics: {
          """
          SnapshotTesting.diffTool = .ksdiff
                          ˄
                          ╰─ warning: 'diffTool' is deprecated: Use 'withSnapshotTesting' to customize the diff tool. See the documentation for more information. [#DeprecatedDeclaration]
          """
        }
      }

      #if os(macOS) || os(Linux)
        // NB: Binary Swift modules can only be read by the exact compiler that produced them, so
        //     importing the package under test with a pinned toolchain requires rebuilding it
        //     with that toolchain, via 'building:'.
        @Test(.enabled(if: isSwiftlyInstalled && hasSwift63SDK))
        func importPackageModule_Swift63() {
          assertCompilation(
            compiler: .swiftly("6.3.1", sdk: URL(fileURLWithPath: swift63SDKPath)),
            building: ["SnapshotTesting"]
          ) {
            """
            import SnapshotTesting
            SnapshotTesting.diffTool = .ksdiff
            """
          } diagnostics: {
            """
            SnapshotTesting.diffTool = .ksdiff
                            ˄
                            ╰─ warning: 'diffTool' is deprecated: Use 'withSnapshotTesting' to customize the diff tool. See the documentation for more information. [#DeprecatedDeclaration]
            """
          }
        }
      #endif

      @Test func mixedTypedAndStringFlags() {
        assertCompilation(flags: [.languageMode(.v6), "-warnings-as-errors"]) {
          """
          class Counter {}
          enum Sharing { static var counter = Counter() }
          func greet() {
            let name = "Blob"
          }
          """
        } diagnostics: {
          """
          enum Sharing { static var counter = Counter() }
                                    ˄
                                    ╰─ error: static property 'counter' is not concurrency-safe because it is nonisolated global shared mutable state [#MutableGlobalVariable]
                                    ╰─ note: convert 'counter' to a 'let' constant to make 'Sendable' shared state immutable
                                    ╰─ note: add '@MainActor' to make static property 'counter' part of global actor 'MainActor'
                                    ╰─ note: disable concurrency-safety checks if accesses are protected by an external synchronization mechanism
            let name = "Blob"
                ˄
                ╰─ error: initialization of immutable value 'name' was never used; consider replacing with assignment to '_' or removing it [#NoUsage]
          """
        }
      }

      @Test func withCompilationTestingScope() {
        withCompilationTesting(flags: [.languageMode(.v6)]) {
          assertCompilation {
            """
            class Counter {}
            enum Sharing { static var counter = Counter() }
            """
          } diagnostics: {
            """
            enum Sharing { static var counter = Counter() }
                                      ˄
                                      ╰─ error: static property 'counter' is not concurrency-safe because it is nonisolated global shared mutable state [#MutableGlobalVariable]
                                      ╰─ note: convert 'counter' to a 'let' constant to make 'Sendable' shared state immutable
                                      ╰─ note: add '@MainActor' to make static property 'counter' part of global actor 'MainActor'
                                      ╰─ note: disable concurrency-safety checks if accesses are protected by an external synchronization mechanism
            """
          }
        }
      }
    }

    @Suite(.compilation(flags: [.languageMode(.v6)]))
    struct CompilationTraitTests {
      @Test func suiteFlags() {
        assertCompilation {
          """
          class Counter {}
          enum Sharing { static var counter = Counter() }
          """
        } diagnostics: {
          """
          enum Sharing { static var counter = Counter() }
                                    ˄
                                    ╰─ error: static property 'counter' is not concurrency-safe because it is nonisolated global shared mutable state [#MutableGlobalVariable]
                                    ╰─ note: convert 'counter' to a 'let' constant to make 'Sendable' shared state immutable
                                    ╰─ note: add '@MainActor' to make static property 'counter' part of global actor 'MainActor'
                                    ╰─ note: disable concurrency-safety checks if accesses are protected by an external synchronization mechanism
          """
        }
      }

      // NB: The suite's '-swift-version 6' diagnoses the mutable static, while the call site's
      //     '-warnings-as-errors' escalates the unused-variable warning, proving both sources of
      //     flags are in effect.
      @Test func callSiteFlagsMergeWithSuiteFlags() {
        assertCompilation(flags: [.warningsAsErrors]) {
          """
          class Counter {}
          enum Sharing { static var counter = Counter() }
          func greet() {
            let name = "Blob"
          }
          """
        } diagnostics: {
          """
          enum Sharing { static var counter = Counter() }
                                    ˄
                                    ╰─ error: static property 'counter' is not concurrency-safe because it is nonisolated global shared mutable state [#MutableGlobalVariable]
                                    ╰─ note: convert 'counter' to a 'let' constant to make 'Sendable' shared state immutable
                                    ╰─ note: add '@MainActor' to make static property 'counter' part of global actor 'MainActor'
                                    ╰─ note: disable concurrency-safety checks if accesses are protected by an external synchronization mechanism
            let name = "Blob"
                ˄
                ╰─ error: initialization of immutable value 'name' was never used; consider replacing with assignment to '_' or removing it [#NoUsage]
          """
        }
      }
    }
  }

  #if os(macOS) || os(Linux)
    private let isSwiftlyInstalled = FileManager.default.isExecutableFile(
      atPath: FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".swiftly")
        .appendingPathComponent("bin")
        .appendingPathComponent("swiftly")
        .path
    )

    // NB: Older toolchains cannot parse the '.swiftinterface' files in newer SDKs, so tests that
    //     import SDK modules with an older toolchain must pin an era-appropriate SDK.
    private let swift62SDKPath = """
      /Applications/Xcode-26.2.0.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs\
      /MacOSX.sdk
      """
    private let hasSwift62SDK = FileManager.default.fileExists(atPath: swift62SDKPath)

    private let swift63SDKPath = """
      /Applications/Xcode-26.6.0.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs\
      /MacOSX.sdk
      """
    private let hasSwift63SDK = FileManager.default.fileExists(atPath: swift63SDKPath)
  #endif
#endif
