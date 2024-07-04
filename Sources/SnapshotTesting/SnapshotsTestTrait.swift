#if canImport(Testing)
  @_spi(Experimental) import Testing

  @_spi(Experimental)
  extension Trait where Self == _SnapshotsTestTrait {
    public static func snapshots(
      diffTool: SnapshotTestingConfiguration.DiffTool = .default,
      record: SnapshotTestingConfiguration.Record = .missing
    ) -> Self {
      _SnapshotsTestTrait(
        configuration: SnapshotTestingConfiguration(
          diffTool: diffTool,
          record: record
        )
      )
    }

    public static func snapshots(
      _ configuration: SnapshotTestingConfiguration
    ) -> Self {
      _SnapshotsTestTrait(configuration: configuration)
    }
  }

  @_spi(Experimental)
  public struct _SnapshotsTestTrait: CustomExecutionTrait, SuiteTrait, TestTrait {
    public let isRecursive = true
    let configuration: SnapshotTestingConfiguration

    public func execute(
      _ function: @escaping () async throws -> Void,
      for test: Test,
      testCase: Test.Case?
    ) async throws {
      try await withSnapshotTesting(
        record: configuration.record,
        diffTool: configuration.diffTool
      ) {
        try await function()
      }
    }
  }
#endif
