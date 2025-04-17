#if canImport(Testing)
  @_spi(Internals) import SnapshotTestingCore
  import Testing

  extension _SnapshotsTestTrait: SuiteTrait, TestTrait {

  }

  #if compiler(>=6.1)
    extension _SnapshotsTestTrait: TestScoping {
      public func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: () async throws -> Void
      ) async throws {
        try await withSnapshotTesting(
          record: configuration.record,
          diffTool: configuration.diffTool
        ) {
          try await File.$counter.withValue(File.Counter()) {
            try await function()
          }
        }
      }
    }
  #endif

  extension Trait where Self == _SnapshotsTestTrait {
    /// Configure snapshot testing in a suite or test.
    public static var snapshots: Self {
      snapshots()
    }

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
#endif
