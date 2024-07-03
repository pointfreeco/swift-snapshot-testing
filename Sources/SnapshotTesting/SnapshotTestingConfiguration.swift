public func withSnapshotTesting<R>(
  diffTool: SnapshotTestingConfiguration.DiffTool? = nil,
  record: SnapshotTestingConfiguration.Record? = nil,
  operation: () async throws -> R
) async rethrows -> R {
  try await SnapshotTestingConfiguration.$current.withValue(
    SnapshotTestingConfiguration(diffTool: diffTool, record: record)
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
    SnapshotTestingConfiguration(diffTool: diffTool, record: record)
  ) {
    try operation()
  }
}

public struct SnapshotTestingConfiguration: Sendable {
  @_spi(Internals)
  @TaskLocal public static var current = Self()

  public var diffTool: DiffTool?
  public var record: Record?

  public init(
    diffTool: DiffTool? = nil,
    record: Record? = nil
  ) {
    self.diffTool = diffTool
    self.record = record
  }

  public enum Record: String, Sendable {
    case always
    case ifMissing
    case never
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
    self = value ? .always : .ifMissing
  }
}
