import XCTest

public var record = false

public func assertSnapshot(
  matching any: Any,
  named name: String? = nil,
  pathExtension: String? = "txt",
  record recording: Bool = SnapshotTesting.record,
  file: StaticString = #file,
  function: String = #function,
  line: UInt = #line)
{
  assertSnapshot(
    matching: snap(any),
    named: name,
    pathExtension: pathExtension,
    record: recording,
    file: file,
    function: function,
    line: line
  )
}

public func assertSnapshot<S: Snapshot>(
  matching snapshot: S,
  named name: String? = nil,
  pathExtension: String? = S.snapshotPathExtension,
  record recording: Bool = SnapshotTesting.record,
  file: StaticString = #file,
  function: String = #function,
  line: UInt = #line)
{
  let snapshotDirectoryUrl: URL = {
    let fileUrl = URL(fileURLWithPath: "\(file)")
    let directoryUrl = fileUrl.deletingLastPathComponent()
    return directoryUrl
      .appendingPathComponent("__Snapshots__")
      .appendingPathComponent(fileUrl.deletingPathExtension().lastPathComponent)
  }()

  let testName: String = {
    let testIdentifier = "\(snapshotDirectoryUrl.absoluteString):\(function)"
    counter[testIdentifier, default: 0] += 1
    return "\(function.dropLast(2)).\(counter[testIdentifier]!)"
  }()

  let snapshotFileUrl = snapshotDirectoryUrl
    .appendingPathComponent(name.map { "\(testName).\($0)" } ?? testName)
    .appendingPathExtension(pathExtension ?? "")
  let fileManager = FileManager.default
  try! fileManager.createDirectory(at: snapshotDirectoryUrl, withIntermediateDirectories: true)

  defer {
    // NB: Linux doesn't have file manager enumeration capabilities, so we skip this work on Linux.
    #if !os(Linux)
    staleSnapshots[snapshotDirectoryUrl, default: Set(
      try! fileManager.contentsOfDirectory(
        at: snapshotDirectoryUrl, includingPropertiesForKeys: nil, options: .skipsHiddenFiles
      )
    )].remove(snapshotFileUrl)
    _ = trackSnapshots
    #endif
  }

  let format = snapshot.snapshotFormat
  if !recording && fileManager.fileExists(atPath: snapshotFileUrl.path) {
    let reference = S.Format.fromDiffableData(try! Data(contentsOf: snapshotFileUrl))
    if let (failure, attachments) = S.Format.diffableDiff(reference, format) {
      if !attachments.isEmpty {
        // NB: Linux doesn't have XCTAttachment, and we don't even need it, so can skip all of this work.
        #if !os(Linux)
        XCTContext.runActivity(named: "Attached Failure Diff") { activity in
          attachments.forEach {
            $0.lifetime = .deleteOnSuccess
            activity.add($0)
          }
        }
        #endif
      }
      XCTFail(failure, file: file, line: line)
    }
  } else {
    try! format.diffableData.write(to: snapshotFileUrl)
    let detail = (format.diffableDescription.map { ":\n\n\($0)" } ?? "")
      .split(separator: "\n", omittingEmptySubsequences: false)
      .prefix(7)
      .map { $0.prefix(80) }
      .joined(separator: "\n")
    XCTFail(
      "Recorded snapshot to \(snapshotFileUrl.path.debugDescription)\(detail)",
      file: file,
      line: line
    )
  }
}

/// Coeffect: global mutable state tracking the number of snapshots per test.
private var counter: [String: Int] = [:]

/// Coeffect: global mutable state tracking stale snapshots.
private var staleSnapshots: [URL: Set<URL>] = [:]

/// Prepares an `atexit` hook to print a list of any stale snapshots (those that were detected in
/// `__Snapshots__` directories but were not used in any assertions).
private var trackSnapshots = {
  atexit {
    let stale = staleSnapshots.flatMap { $1 }
    let count = stale.count
    guard count > 0 else { return }
    let list = stale.map { "  \($0.path.debugDescription)" }.sorted().joined(separator: " \\\n")
    print("Found \(count) stale snapshot\(count == 1 ? "" : "s"):\n\n\(list)")
  }
}()

private func snap<T>(_ value: T, name: String? = nil, indent: Int = 0) -> String {
  let indentation = String(repeating: " ", count: indent)
  let mirror = Mirror(reflecting: value)
  let count = mirror.children.count
  let bullet = count == 0 ? "-" : "▿"

  let description: String
  switch (value, mirror.displayStyle) {
  case (_, .collection?):
    description = count == 1 ? "1 element" : "\(count) elements"
  case (_, .dictionary?):
    description = count == 1 ? "1 key/value pair" : "\(count) key/value pairs"
  case (_, .set?):
    description = count == 1 ? "1 member" : "\(count) members"
  case (_, .tuple?):
    description = count == 1 ? "(1 element)" : "(\(count) elements)"
  case (_, .optional?):
    let subjectType = String(describing: mirror.subjectType)
      .replacingOccurrences(of: " #\\d+", with: "", options: .regularExpression)
    description = count == 0 ? "\(subjectType).none" : "\(subjectType)"
  case (let value as SnapshotStringConvertible, _):
    description = value.snapshotDescription
  case (let value as CustomDebugStringConvertible, _):
    description = value.debugDescription
  case (let value as CustomStringConvertible, _):
    description = value.description
  case (_, .class?), (_, .struct?):
    description = String(describing: mirror.subjectType)
      .replacingOccurrences(of: " #\\d+", with: "", options: .regularExpression)
  case (_, .enum?):
    let subjectType = String(describing: mirror.subjectType)
      .replacingOccurrences(of: " #\\d+", with: "", options: .regularExpression)
    description = count == 0 ? "\(subjectType).\(value)" : "\(subjectType)"
  default:
    description = "(indescribable)"
  }

  let lines = ["\(indentation)\(bullet) \(name.map { "\($0): " } ?? "")\(description)\n"]
    + mirror.children.map { snap($1, name: $0, indent: indent + 2) }

  return lines.joined()
}
