#if canImport(Testing)
  // NB: We are importing only the implementation of Testing because that framework is not available
  //     in Xcode UI test targets.
  @_implementationOnly import Testing

  @_spi(Experimental)
  extension Trait where Self == _SnapshotsTestTrait {
    /// Configure snapshot testing in a suite or test.
    ///
    /// - Parameters:
    ///   - record: The record mode of the test.
    ///   - diffTool: The diff tool to use in failure messages.
    public static func snapshots(
      record: SnapshotTestingConfiguration.Record? = nil,
      diffTool: SnapshotTestingConfiguration.DiffTool? = nil
    ) -> Self {
      _SnapshotsTestTrait(
        configuration: SnapshotTestingConfiguration(
          record: record,
          diffTool: diffTool
        )
      )
    }

    /// Configure snapshot testing in a suite or test.
    ///
    /// - Parameter configuration: The configuration to use.
    public static func snapshots(
      _ configuration: SnapshotTestingConfiguration
    ) -> Self {
      _SnapshotsTestTrait(configuration: configuration)
    }
  }

  /// A type representing the configuration of snapshot testing.
  @_spi(Experimental)
  public struct _SnapshotsTestTrait: SuiteTrait, TestTrait {
    public let isRecursive = true
    let configuration: SnapshotTestingConfiguration

    #if compiler(>=6.1)
      public func scopeProvider(for test: Test, testCase: Test.Case?) -> TestScopeProvider? {
        nil
      }
      @_spi(Experimental)
      public enum TestScopeProvider: TestScoping {
        public func provideScope(
          for test: Test,
          testCase: Test.Case?,
          performing function: @Sendable () async throws -> Void
        ) async throws {
          fatalError()
        }
      }
    #endif
  }
#endif
