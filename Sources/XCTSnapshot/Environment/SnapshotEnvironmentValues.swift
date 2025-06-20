import Foundation

public struct SnapshotEnvironmentValues: Sendable {

  @TaskLocal static var current: SnapshotEnvironmentValues?

  private var values: [ObjectIdentifier: Sendable] = [:]

  init() {}

  public subscript<Key: SnapshotEnvironmentKey>(_ key: Key.Type) -> Key.Value {
    get {
      values[ObjectIdentifier(key)] as? Key.Value ?? Key.defaultValue
    }
    set {
      values[ObjectIdentifier(key)] = newValue
    }
  }
}

public func withTestingEnvironment<R: Sendable>(
  _ mutating: @Sendable (inout SnapshotEnvironmentValues) -> Void,
  operation: () async throws -> R,
  isolation: isolated Actor? = #isolation,
  file: String = #file,
  line: UInt = #line
) async rethrows -> R {
  var argumentValues = SnapshotEnvironmentValues.current ?? SnapshotEnvironmentValues()
  mutating(&argumentValues)
  return try await SnapshotEnvironmentValues.$current.withValue(
    argumentValues,
    operation: operation,
    isolation: isolation,
    file: file,
    line: line
  )
}

public func withTestingEnvironment<R>(
  _ mutating: @Sendable (inout SnapshotEnvironmentValues) -> Void,
  operation: () throws -> R,
  file: String = #file,
  line: UInt = #line
) rethrows -> R {
  var argumentValues = SnapshotEnvironmentValues.current ?? SnapshotEnvironmentValues()
  mutating(&argumentValues)
  return try SnapshotEnvironmentValues.$current.withValue(
    argumentValues,
    operation: operation,
    file: file,
    line: line
  )
}

public func withTestingEnvironment<R: Sendable>(
  record: RecordMode? = nil,
  diffTool: DiffTool? = nil,
  maxConcurrentTests: Int? = nil,
  platform: String? = nil,
  environment mutating: (@Sendable (inout SnapshotEnvironmentValues) -> Void),
  operation: () async throws -> R,
  isolation: isolated Actor? = #isolation,
  file: String = #file,
  line: UInt = #line
) async rethrows -> R {
  return try await withTestingEnvironment(
    {
      mutatingEnvironmentValues(
        record: record,
        diffTool: diffTool,
        maxConcurrentTests: maxConcurrentTests,
        platform: platform,
        mutating: &$0
      )
      mutating(&$0)
    },
    operation: operation,
    isolation: isolation,
    file: file,
    line: line
  )
}

public func withTestingEnvironment<R: Sendable>(
  record: RecordMode? = nil,
  diffTool: DiffTool? = nil,
  maxConcurrentTests: Int? = nil,
  platform: String? = nil,
  operation: () async throws -> R,
  isolation: isolated Actor? = #isolation,
  file: String = #file,
  line: UInt = #line
) async rethrows -> R {
  return try await withTestingEnvironment(
    {
      mutatingEnvironmentValues(
        record: record,
        diffTool: diffTool,
        maxConcurrentTests: maxConcurrentTests,
        platform: platform,
        mutating: &$0
      )
    },
    operation: operation,
    isolation: isolation,
    file: file,
    line: line
  )
}

public func withTestingEnvironment<R>(
  record: RecordMode? = nil,
  diffTool: DiffTool? = nil,
  maxConcurrentTests: Int? = nil,
  platform: String? = nil,
  environment mutating: (@Sendable (inout SnapshotEnvironmentValues) -> Void),
  operation: () throws -> R,
  file: String = #file,
  line: UInt = #line
) rethrows -> R {
  return try withTestingEnvironment(
    {
      mutatingEnvironmentValues(
        record: record,
        diffTool: diffTool,
        maxConcurrentTests: maxConcurrentTests,
        platform: platform,
        mutating: &$0
      )
      mutating(&$0)
    },
    operation: operation,
    file: file,
    line: line
  )
}

public func withTestingEnvironment<R>(
  record: RecordMode? = nil,
  diffTool: DiffTool? = nil,
  maxConcurrentTests: Int? = nil,
  platform: String? = nil,
  operation: () throws -> R,
  file: String = #file,
  line: UInt = #line
) rethrows -> R {
  return try withTestingEnvironment(
    {
      mutatingEnvironmentValues(
        record: record,
        diffTool: diffTool,
        maxConcurrentTests: maxConcurrentTests,
        platform: platform,
        mutating: &$0
      )
    },
    operation: operation,
    file: file,
    line: line
  )
}

private func mutatingEnvironmentValues(
  record: RecordMode?,
  diffTool: DiffTool?,
  maxConcurrentTests: Int?,
  platform: String?,
  mutating environment: inout SnapshotEnvironmentValues
) {
  if let record {
    environment.recordMode = record
  }

  if let diffTool {
    environment.diffTool = diffTool
  }

  if let maxConcurrentTests {
    environment.maxConcurrentTests = maxConcurrentTests
  }

  if let platform {
    environment.platform = platform
  }
}
