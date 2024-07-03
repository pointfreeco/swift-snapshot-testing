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

public struct SnapshotTestingConfiguration: Sendable {
  @_spi(Internals)
  @TaskLocal public static var current: Self?
  
  public var diffTool: DiffTool
  public var record: Record

  public init(
    diffTool: DiffTool,
    record: Record
  ) {
    self.diffTool = diffTool
    self.record = record
  }

  public enum Record: String, Sendable {
    case all
    case missing
    case none
  }

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
    public static let ksdiff = Self {
      "ksdiff \($0) \($1)"
    }
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
  message: "Use 'SnapshotTestingConfiguration.Record' instead of a boolean for the record mode."
)
@available(
  macOS, 
  deprecated: 1,
  message: "Use 'SnapshotTestingConfiguration.Record' instead of a boolean for the record mode."
)
@available(
  tvOS, 
  deprecated: 9999,
  message: "Use 'SnapshotTestingConfiguration.Record' instead of a boolean for the record mode."
)
@available(
  watchOS, 
  deprecated: 9999,
  message: "Use 'SnapshotTestingConfiguration.Record' instead of a boolean for the record mode."
)
@available(
  visionOS, 
  deprecated: 9999,
  message: "Use 'SnapshotTestingConfiguration.Record' instead of a boolean for the record mode."
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
  deprecated: 1,
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
