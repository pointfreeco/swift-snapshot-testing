#if canImport(Testing)
  import Testing

  /// A type representing the configuration of snapshot testing.
  public struct _SnapshotsTestTrait: SuiteTrait, TestTrait {
    public let isRecursive = true
    let configuration: SnapshotTestingConfiguration
  }

  extension Trait where Self == _SnapshotsTestTrait {
    /// Configure snapshot testing in a suite or test.
    public static var snapshots: Self {
      snapshots()
    }

    // Kept unchanged for existing calls and references; the overload below requires
    // imagePixelFormat so the two never conflict.
    /// Configure snapshot testing in a suite or test.
    ///
    /// - Parameters:
    ///   - record: The record mode of the test.
    ///   - diffTool: The diff tool to use in failure messages.
    public static func snapshots(
      record: SnapshotTestingConfiguration.Record? = nil,
      diffTool: SnapshotTestingConfiguration.DiffTool? = nil
    ) -> Self {
      snapshots(record: record, diffTool: diffTool, imagePixelFormat: nil)
    }

    /// Configure snapshot testing in a suite or test.
    ///
    /// - Parameters:
    ///   - record: The record mode of the test.
    ///   - diffTool: The diff tool to use in failure messages.
    ///   - imagePixelFormat: The pixel format image snapshots are recorded and compared in. `nil`
    ///     keeps the format of the enclosing configuration. See
    ///     ``SnapshotTestingConfiguration/ImagePixelFormat-swift.struct``.
    public static func snapshots(
      record: SnapshotTestingConfiguration.Record? = nil,
      diffTool: SnapshotTestingConfiguration.DiffTool? = nil,
      imagePixelFormat: SnapshotTestingConfiguration.ImagePixelFormat?
    ) -> Self {
      _SnapshotsTestTrait(
        configuration: SnapshotTestingConfiguration(
          record: record,
          diffTool: diffTool,
          imagePixelFormat: imagePixelFormat
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

  #if compiler(>=6.1)
    extension _SnapshotsTestTrait: TestScoping {
      public func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: () async throws -> Void
      ) async throws {
        try await withSnapshotTesting(
          record: configuration.record,
          diffTool: configuration.diffTool,
          imagePixelFormat: configuration.imagePixelFormat
        ) {
          try await File.$counter.withValue(File.Counter()) {
            try await function()
          }
        }
      }
    }
  #endif
#endif
