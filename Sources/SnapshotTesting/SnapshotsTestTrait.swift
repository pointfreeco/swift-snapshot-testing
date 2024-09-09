#if canImport(Testing)
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

    // public func execute(
    //   _ function: @escaping () async throws -> Void,
    //   for test: Test,
    //   testCase: Test.Case?
    // ) async throws {
    //   try await withSnapshotTesting(
    //     record: configuration.record,
    //     diffTool: configuration.diffTool
    //   ) {
    //     try await function()
    //   }
    // }
  }
#endif
