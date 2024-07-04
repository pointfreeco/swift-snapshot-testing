/// Customizes `assertSnapshot` for the duration of an operation.
///
/// Use this operation to customize how the `assertSnapshot` function behaves in a test. It is most
/// convenient to use in the context of XCTest where you can wrap `invokeTest` of an `XCTestCase`
/// subclass so that the configuration applies to every test method.
///
/// > Note: To customize tests when using Swift's native Testing library, use the
/// ``Testing/Trait/snapshots(diffTool:record:)`` trait.
///
/// For example, to specify to put an entire test class in record mode you do the following:
///
/// ```swift
/// class FeatureTests: XCTestCase {
///   override func invokeTest() {
///     withSnapshotTesting(record: .all) {
///       super.invokeTest()
///     }
///   }
/// }
/// ```
///
/// - Parameters:
///   - diffTool: The difftool to use while asserting snapshots.
///   - record: The record mode to use while asserting snapshots.
///   - operation: The operation to perform.
public func withSnapshotTesting<R>(
  diffTool: SnapshotTestingConfiguration.DiffTool? = nil,
  record: SnapshotTestingConfiguration.Record? = nil,
  operation: () async throws -> R
) async rethrows -> R {
  try await SnapshotTestingConfiguration.$current.withValue(
    SnapshotTestingConfiguration(
      diffTool: diffTool ?? SnapshotTestingConfiguration.current?.diffTool ?? _diffTool,
      record: record ?? SnapshotTestingConfiguration.current?.record ?? _record
    )
  ) {
    try await operation()
  }
}

/// Customizes `assertSnapshot` for the duration of an operation.
///
/// See ``withSnapshotTesting(diffTool:record:operation:)-7xmhk`` for more information.
public func withSnapshotTesting<R>(
  diffTool: SnapshotTestingConfiguration.DiffTool? = nil,
  record: SnapshotTestingConfiguration.Record? = nil,
  operation: () throws -> R
) rethrows -> R {
  try SnapshotTestingConfiguration.$current.withValue(
    SnapshotTestingConfiguration(
      diffTool: diffTool ?? SnapshotTestingConfiguration.current?.diffTool ?? SnapshotTesting._diffTool,
      record: record ?? SnapshotTestingConfiguration.current?.record ?? _record
    )
  ) {
    try operation()
  }
}

/// The configuration for a snapshot test.
public struct SnapshotTestingConfiguration: Sendable {
  @_spi(Internals)
  @TaskLocal public static var current: Self?
  
  public var diffTool: DiffTool
  public var record: Record

  public init(
    diffTool: DiffTool = .ksdiff,
    record: Record = .missing
  ) {
    self.diffTool = diffTool
    self.record = record
  }
  
  /// The record mode of the snapshot test.
  public enum Record: String, Sendable {
    /// Records all snapshots.
    case all
    /// Records snapshots that are missing.
    case missing
    /// Does not record any snapshots. If a snapshot is missing a test failure will be raised.
    case none
  }
  
  /// Describes the diff command used to diff two files on disk.
  public struct DiffTool: Sendable, ExpressibleByStringLiteral {
    var tool: @Sendable (String, String) -> String
    public init(
      _ tool: @escaping @Sendable (_ currentFilePath: String, _ failedFilePath: String) -> String
    ) {
      self.tool = tool
    }
    public init(stringLiteral value: StringLiteralType) {
      self.tool = { _, _ in value }
    }
    /// The [Kaleidoscope](http://kaleidoscope.app) diff tool.
    public static let ksdiff = Self {
      "ksdiff \($0) \($1)"
    }
    /// The default diff tool.
    public static let `default` = Self {
      """
      @\(minus)
      "file://\($0)"
      @\(plus)
      "file://\($1)"

      To configure output for a custom diff tool, like Kaleidoscope:

          SnapshotTesting.diffTool = "ksdiff"
      """
    }
    public func callAsFunction(currentFilePath: String, failedFilePath: String) -> String {
      self.tool(currentFilePath, failedFilePath)
    }
  }
}

@available(
  iOS, 
  deprecated: 9999,
  message: "Use 'SnapshotTestingConfiguration.Record.all' instead of 'true', and '.missing' instead of 'false'."
)
@available(
  macOS, 
  deprecated: 9999,
  message: "Use 'SnapshotTestingConfiguration.Record.all' instead of 'true', and '.missing' instead of 'false'."
)
@available(
  tvOS, 
  deprecated: 9999,
  message: "Use 'SnapshotTestingConfiguration.Record.all' instead of 'true', and '.missing' instead of 'false'."
)
@available(
  watchOS, 
  deprecated: 9999,
  message: "Use 'SnapshotTestingConfiguration.Record.all' instead of 'true', and '.missing' instead of 'false'."
)
@available(
  visionOS, 
  deprecated: 9999,
  message: "Use 'SnapshotTestingConfiguration.Record.all' instead of 'true', and '.missing' instead of 'false'."
)
extension SnapshotTestingConfiguration.Record: ExpressibleByBooleanLiteral {
  public init(booleanLiteral value: BooleanLiteralType) {
    self = value ? .all : .missing
  }
}
@available(
  iOS,
  deprecated: 9999,
  message: "Use 'SnapshotTestingConfiguration.Diff.default' instead of a 'nil' value for 'diffTool'."
)
@available(
  macOS,
  deprecated: 9999,
  message: "Use 'SnapshotTestingConfiguration.Diff.default' instead of a 'nil' value for 'diffTool'."
)
@available(
  tvOS,
  deprecated: 9999,
  message: "Use 'SnapshotTestingConfiguration.Diff.default' instead of a 'nil' value for 'diffTool'."
)
@available(
  watchOS,
  deprecated: 9999,
  message: "Use 'SnapshotTestingConfiguration.Diff.default' instead of a 'nil' value for 'diffTool'."
)
@available(
  visionOS,
  deprecated: 9999,
  message: "Use 'SnapshotTestingConfiguration.Diff.default' instead of a 'nil' value for 'diffTool'."
)
extension SnapshotTestingConfiguration.DiffTool: ExpressibleByNilLiteral {
  public init(nilLiteral: ()) {
    self = .default
  }
}
