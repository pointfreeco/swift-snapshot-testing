#if canImport(Testing)
  import Testing

  /// A type representing the configuration of snapshot testing.
  @available(*, deprecated, message: "Migrate to new the SnapshotTesting API")
  public struct _SnapshotsTestTrait: SuiteTrait, TestTrait {
    public let isRecursive = true
    let configuration: SnapshotTestingConfiguration
  }

  @available(*, deprecated)
  extension Trait where Self == _SnapshotsTestTrait {
    /// Configure snapshot testing in a suite or test.
    @available(*, deprecated, message: "Replace with .record(..) or .diffTool(..)")
    public static var snapshots: Self {
      snapshots()
    }

    /// Configure snapshot testing in a suite or test.
    ///
    /// - Parameters:
    ///   - record: The record mode of the test.
    ///   - diffTool: The diff tool to use in failure messages.
    @available(*, deprecated, message: "Replace with .record(..) or .diffTool(..)")
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
    @available(*, deprecated, message: "Replace with .record(..) or .diffTool(..)")
    public static func snapshots(
      _ configuration: SnapshotTestingConfiguration
    ) -> Self {
      _SnapshotsTestTrait(configuration: configuration)
    }
  }

  #if compiler(>=6.1)
    @available(*, deprecated)
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
#endif
