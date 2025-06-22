import XCTest

// MARK: - Assert snapshot

/// Validates a single snapshot of an input value using a specific configuration.
///
/// - Parameters:
///   - input: Input value to serialize and compare with the stored snapshot.
///   - configuration: Configuration defining how the snapshot is generated (e.g., layout, image precision).
///   - serialization: Serialization configuration to control details like scaling.
///   - name: Optional identifier for the snapshot (useful in tests with multiple snapshots).
///   - recording: Recording mode override for this test (e.g., `.always` to force update).
///   - fileID, filePath, testName, line, column: Internal parameters for test location tracking.
///
/// - WARNING: Automatic snapshot counting in a single test relies on the position where `assert` is called.
///   If using a for-loop, explicitly configure the `name` parameter.
///
/// Notes:
///   - If `recording` isn't defined, uses the global value from `TestingSession.shared.record`, or from Testing Traits, or when wrapped by `withTestingEnvironment(record:operation:)`.
///
/// Example:
///   ```swift
///   try await assert(of: myView, as: .image(layout: .iPhone15ProMax), named: "dark_mode")
///   ```
public func assert<Input: Sendable, Output: BytesRepresentable>(
  of input: @Sendable @autoclosure () async throws -> Input,
  as snapshot: AsyncSnapshot<Input, Output>,
  serialization: DataSerialization = DataSerialization(),
  named name: String? = nil,
  record recording: RecordMode? = nil,
  snapshotDirectory: String? = nil,
  timeout: TimeInterval = .zero,
  isolation: isolated Actor? = #isolation,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  testName: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) async throws {
  let failure = try await verify(
    of: await input(),
    as: snapshot,
    serialization: serialization,
    named: name,
    record: recording,
    snapshotDirectory: snapshotDirectory,
    timeout: timeout,
    isolation: isolation,
    fileID: fileID,
    file: filePath,
    testName: testName,
    line: line,
    column: column
  )

  guard let message = failure else { return }

  TestingSystem.shared.record(
    message: message,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
}

/// Validates multiple snapshots of an input value using named configurations.
///
/// - Parameters:
///   - input: Shared input value for all snapshots.
///   - strategies: Dictionary of named configurations (key = snapshot name).
///   - serialization: Shared serialization configuration for all snapshots.
///   - recording: Recording mode override for all snapshots.
///   - fileID, filePath, testName, line, column: Internal parameters for test location tracking.
///
/// - WARNING: Automatic snapshot counting in a single test relies on the position where `assert` is called.
///   If using a for-loop, explicitly configure the `name` parameter.
///
/// Notes:
///   - Executes all snapshots sequentially using each dictionary configuration.
///   - Each key in the `strategies` dictionary becomes the snapshot name.
///   - Useful for testing the same input with different layouts or precisions.
///
/// Example:
///   ```swift
///   let strategies: [String: Snapshot] = [
///       "portrait": .image(layout: .iPhone15ProMax),
///       "landscape": .image(layout: .iPhone15ProMax(.init(traits: .landscape)))
///   ]
///   try await assertSnapshots(myView, as: strategies)
///   ```
public func assert<Input: Sendable, Output: BytesRepresentable>(
  of input: @Sendable @autoclosure () async throws -> Input,
  as strategies: [String: AsyncSnapshot<Input, Output>],
  serialization: DataSerialization = DataSerialization(),
  record recording: RecordMode? = nil,
  snapshotDirectory: String? = nil,
  timeout: TimeInterval = .zero,
  isolation: isolated Actor? = #isolation,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  testName: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) async throws {
  for (name, configuration) in strategies {
    try await assert(
      of: await input(),
      as: configuration,
      serialization: serialization,
      named: name,
      record: recording,
      snapshotDirectory: snapshotDirectory,
      timeout: timeout,
      isolation: isolation,
      fileID: fileID,
      file: filePath,
      testName: testName,
      line: line,
      column: column
    )
  }
}

/// Validates multiple snapshots of an input value using multiple configurations.
///
/// - Parameters:
///   - input: Shared input value for all snapshots.
///   - strategies: Array of configurations for each snapshot.
///   - serialization: Shared serialization configuration.
///   - recording: Recording mode override for all snapshots.
///   - fileID, filePath, testName, line, column: Internal parameters for test location tracking.
///
/// - WARNING: Automatic snapshot counting in a single test relies on the position where `assert` is called.
///   If using a for-loop, explicitly configure the `name` parameter.
///
/// Notes:
///   - Unlike the dictionary version, does not use explicit names for each snapshot.
///   - Prefer the dictionary version when meaningful names are required.
///   - Useful for tests with similar configurations that don't require individual identification.
///
/// Example:
///   ```swift
///   let strategies = [
///       .image(layout: .iPhone15ProMax),
///       .image(precision: 0.95)
///   ]
///   try await assertSnapshots(myView, as: strategies)
///   ```
public func assert<Input: Sendable, Output: BytesRepresentable>(
  of input: @Sendable @autoclosure () async throws -> Input,
  as strategies: [AsyncSnapshot<Input, Output>],
  serialization: DataSerialization = DataSerialization(),
  record recording: RecordMode? = nil,
  snapshotDirectory: String? = nil,
  timeout: TimeInterval = .zero,
  isolation: isolated Actor? = #isolation,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  testName: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) async throws {
  let uniqueID = TestingSession.shared.forLoop(
    fileID: fileID,
    filePath: filePath,
    function: String(describing: testName),
    line: line,
    column: column
  )

  for (index, strategy) in strategies.enumerated() {
    try await assert(
      of: await input(),
      as: strategy,
      serialization: serialization,
      named: "\(uniqueID)@\(index + 1)",
      record: recording,
      snapshotDirectory: snapshotDirectory,
      timeout: timeout,
      isolation: isolation,
      fileID: fileID,
      file: filePath,
      testName: testName,
      line: line,
      column: column
    )
  }
}

// MARK: - Sync snapshot

public func assert<Input, Output: BytesRepresentable>(
  of input: @autoclosure () throws -> Input,
  as snapshot: SyncSnapshot<Input, Output>,
  serialization: DataSerialization = DataSerialization(),
  named name: String? = nil,
  record recording: RecordMode? = nil,
  snapshotDirectory: String? = nil,
  timeout: TimeInterval = 5,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  testName: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) throws {
  let failure = try verify(
    of: input(),
    as: snapshot,
    serialization: serialization,
    named: name,
    record: recording,
    snapshotDirectory: snapshotDirectory,
    timeout: timeout,
    fileID: fileID,
    file: filePath,
    testName: testName,
    line: line,
    column: column
  )

  guard let message = failure else { return }

  TestingSystem.shared.record(
    message: message,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
}

public func assert<Input, Output: BytesRepresentable>(
  of input: Input,
  as strategies: [String: SyncSnapshot<Input, Output>],
  serialization: DataSerialization = DataSerialization(),
  record recording: RecordMode? = nil,
  snapshotDirectory: String? = nil,
  timeout: TimeInterval = 5,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  testName: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) throws {
  for (name, configuration) in strategies {
    try? assert(
      of: input,
      as: configuration,
      serialization: serialization,
      named: name,
      record: recording,
      snapshotDirectory: snapshotDirectory,
      timeout: timeout,
      fileID: fileID,
      file: filePath,
      testName: testName,
      line: line,
      column: column
    )
  }
}

public func assert<Input, Output: BytesRepresentable>(
  of input: Input,
  as strategies: [SyncSnapshot<Input, Output>],
  serialization: DataSerialization = DataSerialization(),
  record recording: RecordMode? = nil,
  snapshotDirectory: String? = nil,
  timeout: TimeInterval = 5,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  testName: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) async throws {
  for strategy in strategies {
    try? assert(
      of: input,
      as: strategy,
      serialization: serialization,
      record: recording,
      snapshotDirectory: snapshotDirectory,
      timeout: timeout,
      fileID: fileID,
      file: filePath,
      testName: testName,
      line: line,
      column: column
    )
  }
}

public func verify<Input: Sendable, Output: BytesRepresentable>(
  of input: @Sendable @autoclosure () async throws -> Input,
  as snapshot: AsyncSnapshot<Input, Output>,
  serialization: DataSerialization = DataSerialization(),
  named name: String? = nil,
  record recording: RecordMode? = nil,
  snapshotDirectory: String? = nil,
  timeout: TimeInterval = .zero,
  isolation: isolated Actor? = #isolation,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  testName: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) async throws -> String? {
  let engine = FileSnapshotEngine<Async<Input, Output>>(
    sourceURL: snapshotDirectory.map {
      URL(fileURLWithPath: $0, isDirectory: true)
    }
  )

  let tester = SnapshotTester(
    engine: engine,
    record: recording,
    timeout: timeout,
    name: name,
    serialization: serialization,
    fileID: fileID,
    filePath: filePath,
    function: testName,
    line: line,
    column: column
  )

  return try await tester(input(), for: snapshot)?.message
}

public func verify<Input, Output: BytesRepresentable>(
  of input: @autoclosure () throws -> Input,
  as snapshot: SyncSnapshot<Input, Output>,
  serialization: DataSerialization = DataSerialization(),
  named name: String? = nil,
  record recording: RecordMode? = nil,
  snapshotDirectory: String? = nil,
  timeout: TimeInterval = 5,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  testName: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) throws -> String? {
  let engine = FileSnapshotEngine<Sync<Input, Output>>(
    sourceURL: snapshotDirectory.map {
      URL(fileURLWithPath: $0, isDirectory: true)
    }
  )

  let tester = SnapshotTester(
    engine: engine,
    record: recording,
    timeout: timeout,
    name: name,
    serialization: serialization,
    fileID: fileID,
    filePath: filePath,
    function: testName,
    line: line,
    column: column
  )

  return try tester(input(), for: snapshot)?.message
}
