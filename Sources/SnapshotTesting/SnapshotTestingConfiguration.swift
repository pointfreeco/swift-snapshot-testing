import ImageSerializationPlugin

/// Customizes `assertSnapshot` for the duration of an operation.
///
/// Use this operation to customize how the `assertSnapshot` function behaves in a test. It is most
/// convenient to use in the context of XCTest where you can wrap `invokeTest` of an `XCTestCase`
/// subclass so that the configuration applies to every test method.
///
/// > Note: To customize tests when using Swift's native Testing library, use the
/// > ``Testing/Trait/snapshots(diffTool:record:)`` trait.
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
///   - record: The record mode to use while asserting snapshots.
///   - diffTool: The diff tool to use while asserting snapshots.
///   - imageFormat: The image format used while encoding/decoding images(default: .png).
///   - operation: The operation to perform.
public func withSnapshotTesting<R>(
  record: SnapshotTestingConfiguration.Record? = nil,
  diffTool: SnapshotTestingConfiguration.DiffTool? = nil,
  imageFormat: ImageSerializationFormat? = nil,
  operation: () throws -> R
) rethrows -> R {
  try SnapshotTestingConfiguration.$current.withValue(
    SnapshotTestingConfiguration(
      record: record ?? SnapshotTestingConfiguration.current?.record ?? _record,
      diffTool: diffTool ?? SnapshotTestingConfiguration.current?.diffTool ?? SnapshotTesting._diffTool,
      imageFormat: imageFormat ?? SnapshotTestingConfiguration.current?.imageFormat ?? _imageFormat
    )
  ) {
    try operation()
  }
}

/// Customizes `assertSnapshot` for the duration of an asynchronous operation.
///
/// See ``withSnapshotTesting(record:diffTool:imageFormat:operation:)-2kuyr`` for more information.
public func withSnapshotTesting<R>(
  record: SnapshotTestingConfiguration.Record? = nil,
  diffTool: SnapshotTestingConfiguration.DiffTool? = nil,
  imageFormat: ImageSerializationFormat? = nil,
  operation: () async throws -> R
) async rethrows -> R {
  try await SnapshotTestingConfiguration.$current.withValue(
    SnapshotTestingConfiguration(
      record: record ?? SnapshotTestingConfiguration.current?.record ?? _record,
      diffTool: diffTool ?? SnapshotTestingConfiguration.current?.diffTool ?? _diffTool,
      imageFormat: imageFormat ?? SnapshotTestingConfiguration.current?.imageFormat ?? _imageFormat
    )
  ) {
    try await operation()
  }
}

/// The configuration for a snapshot test.
public struct SnapshotTestingConfiguration: Sendable {
  @_spi(Internals)
  @TaskLocal public static var current: Self?

  /// The diff tool use to print helpful test failure messages.
  ///
  /// See ``DiffTool-swift.struct`` for more information.
  public var diffTool: DiffTool?

  /// The recording strategy to use while running snapshot tests.
  ///
  /// See ``Record-swift.struct`` for more information.
  public var record: Record?
  
  /// The image format to use while encoding/decoding snapshot tests.
  public var imageFormat: ImageSerializationFormat?

  public init(
    record: Record?,
    diffTool: DiffTool?,
    imageFormat: ImageSerializationFormat?
  ) {
    self.diffTool = diffTool
    self.record = record
    self.imageFormat = imageFormat
  }

  /// The record mode of the snapshot test.
  ///
  /// There are 4 primary strategies for recording: ``Record-swift.struct/all``,
  /// ``Record-swift.struct/missing``, ``Record-swift.struct/never`` and
  /// ``Record-swift.struct/failed``
  public struct Record: Equatable, Sendable {
    private let storage: Storage

    public init?(rawValue: String) {
      switch rawValue {
      case "all":
        self.storage = .all
      case "failed":
        self.storage = .failed
      case "missing":
        self.storage = .missing
      case "never":
        self.storage = .never
      default:
        return nil
      }
    }

    /// Records all snapshots to disk, no matter what.
    public static let all = Self(storage: .all)

    /// Records snapshots for assertions that fail. This can be useful for tests that use precision
    /// thresholds so that passing tests do not re-record snapshots that are subtly different but
    /// still within the threshold.
    public static let failed = Self(storage: .failed)

    /// Records only the snapshots that are missing from disk.
    public static let missing = Self(storage: .missing)

    /// Does not record any snapshots. If a snapshot is missing a test failure will be raised. This
    /// option is appropriate when running tests on CI so that re-tries of tests do not
    /// surprisingly pass after snapshots are unexpectedly generated.
    public static let never = Self(storage: .never)

    private init(storage: Storage) {
      self.storage = storage
    }

    private enum Storage: Equatable, Sendable {
      case all
      case failed
      case missing
      case never
    }
  }

  /// Describes the diff command used to diff two files on disk.
  ///
  /// This type can be created with a closure that takes two arguments: the first argument is
  /// is a file path to the currently recorded snapshot on disk, and the second argument is the
  /// file path to a _failed_ snapshot that was recorded to a temporary location on disk. You can
  /// use these two file paths to construct a command that can be used to compare the two files.
  ///
  /// For example, to use ImageMagick's `compare` tool and pipe the result into Preview.app, you
  /// could create the following `DiffTool`:
  ///
  /// ```swift
  /// extension SnapshotTestingConfiguration.DiffTool {
  ///   static let compare = Self {
  ///     "compare \"\($0)\" \"\($1)\" png: | open -f -a Preview.app"
  ///   }
  /// }
  /// ```
  ///
  /// `DiffTool` also comes with two values: ``DiffTool-swift.struct/ksdiff`` for printing a
  /// command for opening [Kaleidoscope](https://kaleidoscope.app), and
  /// ``DiffTool-swift.struct/default`` for simply printing the two URLs to the test failure
  /// message.
  public struct DiffTool: Sendable, ExpressibleByStringLiteral {
    var tool: @Sendable (_ currentFilePath: String, _ failedFilePath: String) -> String

    public init(
      _ tool: @escaping @Sendable (_ currentFilePath: String, _ failedFilePath: String) -> String
    ) {
      self.tool = tool
    }

    public init(stringLiteral value: StringLiteralType) {
      self.tool = { "\(value) \($0) \($1)" }
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

      To configure output for a custom diff tool, use 'withSnapshotTesting'. For example:

          withSnapshotTesting(diffTool: .ksdiff) {
            // ...
          }
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
  message: "Use '.all' instead of 'true', and '.missing' instead of 'false'."
)
@available(
  macOS,
  deprecated: 9999,
  message: "Use '.all' instead of 'true', and '.missing' instead of 'false'."
)
@available(
  tvOS,
  deprecated: 9999,
  message: "Use '.all' instead of 'true', and '.missing' instead of 'false'."
)
@available(
  watchOS,
  deprecated: 9999,
  message: "Use '.all' instead of 'true', and '.missing' instead of 'false'."
)
@available(
  visionOS,
  deprecated: 9999,
  message: "Use '.all' instead of 'true', and '.missing' instead of 'false'."
)
extension SnapshotTestingConfiguration.Record: ExpressibleByBooleanLiteral {
  public init(booleanLiteral value: BooleanLiteralType) {
    self = value ? .all : .missing
  }
}

@available(
  *,
  deprecated,
  renamed: "SnapshotTestingConfiguration.DiffTool.default",
  message: "Use '.default' instead of a 'nil' value for 'diffTool'."
)
extension SnapshotTestingConfiguration.DiffTool: ExpressibleByNilLiteral {
  public init(nilLiteral: ()) {
    self = .default
  }
}
