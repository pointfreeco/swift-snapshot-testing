// Kept unchanged for existing calls and references; the overload below requires imagePixelFormat
// so the two never conflict.
/// Customizes `assertSnapshot` for the duration of an operation.
///
/// Use this operation to customize how the `assertSnapshot` function behaves in a test. It is most
/// convenient to use in the context of XCTest where you can wrap `invokeTest` of an `XCTestCase`
/// subclass so that the configuration applies to every test method.
///
/// > Note: To customize tests when using Swift's native Testing library, use the
/// > ``Testing/Trait/snapshots(record:diffTool:)`` trait.
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
///   - operation: The operation to perform.
public func withSnapshotTesting<R>(
  record: SnapshotTestingConfiguration.Record? = nil,
  diffTool: SnapshotTestingConfiguration.DiffTool? = nil,
  operation: () throws -> R
) rethrows -> R {
  try withSnapshotTesting(
    record: record, diffTool: diffTool, imagePixelFormat: nil, operation: operation)
}

/// Customizes `assertSnapshot`, including the pixel format of image snapshots, for the duration of
/// an operation.
///
/// See ``withSnapshotTesting(record:diffTool:operation:)-2kuyr`` for more information.
///
/// - Parameters:
///   - record: The record mode to use while asserting snapshots.
///   - diffTool: The diff tool to use while asserting snapshots.
///   - imagePixelFormat: The pixel format image snapshots are recorded and compared in. `nil`
///     keeps the format of the enclosing configuration. See
///     ``SnapshotTestingConfiguration/ImagePixelFormat-swift.struct``.
///   - operation: The operation to perform.
public func withSnapshotTesting<R>(
  record: SnapshotTestingConfiguration.Record? = nil,
  diffTool: SnapshotTestingConfiguration.DiffTool? = nil,
  imagePixelFormat: SnapshotTestingConfiguration.ImagePixelFormat?,
  operation: () throws -> R
) rethrows -> R {
  try SnapshotTestingConfiguration.$current.withValue(
    SnapshotTestingConfiguration(
      record: record ?? SnapshotTestingConfiguration.current?.record ?? _record,
      diffTool: diffTool ?? SnapshotTestingConfiguration.current?.diffTool
        ?? SnapshotTesting._diffTool,
      // nil keeps the enclosing configuration's format.
      imagePixelFormat: imagePixelFormat
        ?? SnapshotTestingConfiguration.current?.imagePixelFormat
    )
  ) {
    try operation()
  }
}

// Kept unchanged for existing calls and references; the overload below requires imagePixelFormat
// so the two never conflict.
/// Customizes `assertSnapshot` for the duration of an asynchronous operation.
///
/// See ``withSnapshotTesting(record:diffTool:operation:)-2kuyr`` for more information.
public func withSnapshotTesting<R>(
  record: SnapshotTestingConfiguration.Record? = nil,
  diffTool: SnapshotTestingConfiguration.DiffTool? = nil,
  operation: () async throws -> R
) async rethrows -> R {
  try await withSnapshotTesting(
    record: record, diffTool: diffTool, imagePixelFormat: nil, operation: operation)
}

/// Customizes `assertSnapshot`, including the pixel format of image snapshots, for the duration of
/// an asynchronous operation.
///
/// See ``withSnapshotTesting(record:diffTool:operation:)-2kuyr`` for more information.
///
/// - Parameters:
///   - record: The record mode to use while asserting snapshots.
///   - diffTool: The diff tool to use while asserting snapshots.
///   - imagePixelFormat: The pixel format image snapshots are recorded and compared in. `nil`
///     keeps the format of the enclosing configuration. See
///     ``SnapshotTestingConfiguration/ImagePixelFormat-swift.struct``.
///   - operation: The operation to perform.
public func withSnapshotTesting<R>(
  record: SnapshotTestingConfiguration.Record? = nil,
  diffTool: SnapshotTestingConfiguration.DiffTool? = nil,
  imagePixelFormat: SnapshotTestingConfiguration.ImagePixelFormat?,
  operation: () async throws -> R
) async rethrows -> R {
  try await SnapshotTestingConfiguration.$current.withValue(
    SnapshotTestingConfiguration(
      record: record ?? SnapshotTestingConfiguration.current?.record ?? _record,
      diffTool: diffTool ?? SnapshotTestingConfiguration.current?.diffTool ?? _diffTool,
      // nil keeps the enclosing configuration's format.
      imagePixelFormat: imagePixelFormat
        ?? SnapshotTestingConfiguration.current?.imagePixelFormat
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

  /// The pixel format image snapshots are recorded and compared in.
  ///
  /// See ``ImagePixelFormat-swift.struct`` for more information.
  public var imagePixelFormat: ImagePixelFormat?

  // Kept unchanged for existing calls and references; the initializer below requires
  // imagePixelFormat so the two never conflict.
  public init(
    record: Record?,
    diffTool: DiffTool?
  ) {
    self.init(record: record, diffTool: diffTool, imagePixelFormat: nil)
  }

  /// Creates a configuration. A `nil` value leaves that setting to an enclosing configuration or
  /// the default.
  ///
  /// - Parameters:
  ///   - record: The recording strategy to use while running snapshot tests.
  ///   - diffTool: The diff tool to use in failure messages.
  ///   - imagePixelFormat: The pixel format image snapshots are recorded and compared in.
  public init(
    record: Record?,
    diffTool: DiffTool?,
    imagePixelFormat: ImagePixelFormat?
  ) {
    self.diffTool = diffTool
    self.record = record
    self.imagePixelFormat = imagePixelFormat
  }

  /// The pixel format image snapshots are recorded and compared in.
  ///
  /// Snapshots render the same way in every format; the format decides how they are stored as
  /// references and what they are compared in. It is applied when a snapshot is recorded or
  /// compared, so it covers every image strategy, including those that hand back finished images
  /// (web, scene and sprite view snapshots and plain `UIImage` and `NSImage` values). Re-record
  /// references when the format changes: references recorded in another format still compare, but
  /// without this format's benefits, and exact comparisons can fail on rounding differences.
  ///
  /// ``automatic`` stores references as the platform's PNG encoding of each snapshot and, on iOS
  /// and tvOS, compares in 8-bit sRGB, so every comparison converts both the reference and the
  /// snapshot. The other formats store references in the format they compare in, so a matching
  /// comparison converts only the snapshot, once, and store fully opaque snapshots without an alpha
  /// channel. See <doc:ChoosingAnImagePixelFormat> for the trade-offs.
  ///
  /// > Note: Applies to the iOS, tvOS and macOS image strategies, including on Mac Catalyst.
  /// > watchOS and visionOS have no image strategies.
  public struct ImagePixelFormat: Equatable, Sendable {
    let storage: Storage

    /// Records the platform's PNG encoding of each snapshot and compares in an 8-bit sRGB context,
    /// or on macOS in the reference's own colorspace and bit depth. The historical pipeline.
    ///
    /// The encoding's bit depth and color handling vary with the platform, runtime and content: on
    /// iOS 26 and later, wide-gamut renders encode as 16-bit Display P3, while earlier runtimes
    /// encode those holding only sRGB colors at 8 bits. On iOS and tvOS, the comparison clips
    /// colors outside the sRGB gamut, so differences between them can go undetected.
    public static let automatic = Self(storage: .automatic)

    /// Converts each snapshot to an 8-bit sRGB bitmap and compares in that same format.
    ///
    /// Equivalent to `sRGB(bitDepth: .eight)`. See ``sRGB(bitDepth:)``.
    public static let sRGB = Self.sRGB(bitDepth: .eight)

    /// Converts each snapshot to an sRGB bitmap of the given bit depth before it is recorded or
    /// compared, and compares in that same format.
    ///
    /// On iOS and tvOS, handles color like ``automatic``: colors outside the sRGB gamut are
    /// clipped, `perceptualPrecision` is measured the same way, and references store colors defined
    /// in 8-bit sRGB exactly. On macOS, ``automatic`` compares in the reference's own format, so it
    /// keeps wide-gamut colors that this format clips, and view snapshots render in 8-bit Generic
    /// RGB, which clips some saturated sRGB colors, so their colors aren't stored exactly.
    /// References are already in the comparison format. Results close to a threshold can differ
    /// slightly from ``automatic``, whose references go through the platform's PNG encoding.
    ///
    /// The bit depth mirrors ``displayP3(bitDepth:)`` so both colorspaces offer the same choice. At
    /// 16 bits, differences smaller than one 8-bit step, such as small changes to blending,
    /// gradients or anti-aliasing, are kept rather than rounded away, at about twice the cost of
    /// 8 bits. Those differences are rarely visible, and `displayP3(bitDepth: .sixteen)` keeps them
    /// too while also comparing colors outside sRGB.
    ///
    /// - Parameter bitDepth: The number of bits stored per color component.
    public static func sRGB(bitDepth: BitDepth) -> Self {
      Self(storage: .sRGB(bitDepth))
    }

    /// Converts each snapshot to an 8-bit Display P3 bitmap and compares in that same format.
    ///
    /// Equivalent to `displayP3(bitDepth: .eight)`. See ``displayP3(bitDepth:)``.
    public static let displayP3 = Self.displayP3(bitDepth: .eight)

    /// Converts each snapshot to a Display P3 bitmap of the given bit depth and compares in that
    /// same format.
    ///
    /// Snapshots render exactly as they do with ``automatic`` and are converted once before they
    /// are recorded or compared. Snapshots, references and the comparison context then share one
    /// colorspace and bit depth, so snapshots that match their reference byte for byte compare without
    /// any per-pixel colorspace conversion, and wide-gamut colors are compared without clipping.
    ///
    /// Comparisons that fall back to `perceptualPrecision` color match every pixel and measure the
    /// difference between the actual colors, while ``automatic`` keeps its historical measure for
    /// images in the same colorspace, so a threshold can pass or fail differently in the two
    /// formats.
    ///
    /// - Parameter bitDepth: The number of bits stored per color component.
    public static func displayP3(bitDepth: BitDepth) -> Self {
      Self(storage: .displayP3(bitDepth))
    }

    /// The number of bits stored per color component of an ``sRGB(bitDepth:)`` or
    /// ``displayP3(bitDepth:)`` snapshot.
    public struct BitDepth: Equatable, Sendable {
      let bitsPerComponent: Int

      /// 8 bits per component. References encode as 8-bit PNGs, smaller than the 16-bit references
      /// wide-gamut renders can produce with ``ImagePixelFormat-swift.struct/automatic``.
      ///
      /// On iOS and tvOS, 8-bit sRGB stores colors defined in 8-bit sRGB exactly. Converting to
      /// 8-bit Display P3 quantizes: about three quarters of the 8-bit sRGB colors share a Display
      /// P3 code with a neighbor, mostly less than 1 ΔE76 apart and at most about 2, so those
      /// differences compare equal, even at full precision.
      public static let eight = Self(bitsPerComponent: 8)

      /// 16 bits per component. Keeps differences smaller than one 8-bit step. In Display P3 it
      /// keeps every Display P3 color, and every 8-bit sRGB color of a wide-gamut render, distinct;
      /// converting an 8-bit sRGB image still merges about 2% of its colors, neighbors one step
      /// apart in a component near zero, at most about 1.2 ΔE76 apart. References are about the
      /// size of 16-bit ``ImagePixelFormat-swift.struct/automatic`` ones, or around a fifth smaller
      /// for fully opaque snapshots, and comparisons cost about twice as much as 8-bit ones.
      public static let sixteen = Self(bitsPerComponent: 16)
    }

    enum Storage: Equatable, Sendable {
      case automatic
      case sRGB(BitDepth)
      case displayP3(BitDepth)
    }
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
      "ksdiff \"\($0)\" \"\($1)\""
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
