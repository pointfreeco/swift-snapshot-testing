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
  let snapshot: String = {
    var string = ""
    dump(any, to: &string)
    return string
      // Scrub NSObject pointers
      .replacingOccurrences(of: ": 0x[\\da-f]+?(?=> #\\d+)", with: "", options: .regularExpression)
  }()

  assertSnapshot(
    matching: snapshot,
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
  let snapshotDirectoryUrl = URL(fileURLWithPath: "\(file)")
    .deletingPathExtension()
  let testName = "\(function.dropLast(2))"
  let snapshotFileUrl = snapshotDirectoryUrl
    .appendingPathComponent(name.map { "\(testName).\($0)" } ?? testName)
    .appendingPathExtension(pathExtension ?? "")
  let fileManager = FileManager.default
  try! fileManager
    .createDirectory(at: snapshotDirectoryUrl, withIntermediateDirectories: true, attributes: nil)

  defer {
    staleSnapshots[snapshotDirectoryUrl, default: Set(
      try! fileManager.contentsOfDirectory(
        at: snapshotDirectoryUrl, includingPropertiesForKeys: nil, options: .skipsHiddenFiles
      )
    )].remove(snapshotFileUrl)
    _ = trackSnapshots
  }

  let format = snapshot.snapshotFormat
  if !recording && fileManager.fileExists(atPath: snapshotFileUrl.path) {
    let expected = S.Format.fromDiffableData(try! Data(contentsOf: snapshotFileUrl, options: []))
    if let (failure, attachments) = S.Format.diffableDiff(expected, format) {
      XCTFail(failure, file: file, line: line)
      XCTContext.runActivity(named: "Attached Failure Diff") { activity in
        attachments.forEach {
          $0.lifetime = .deleteOnSuccess
          activity.add($0)
        }
      }
    }
  } else {
    try! format.diffableData.write(to: snapshotFileUrl)
    XCTFail(
      "Recorded snapshot to \(snapshotFileUrl.path.debugDescription)"
        + (format.diffableDescription.map { ":\n\n\($0)" } ?? ""),
      file: file,
      line: line
    )
  }
}

private var staleSnapshots: [URL: Set<URL>] = [:]

private var trackSnapshots = {
  atexit {
    let stale = staleSnapshots.flatMap { $1 }
    let count = stale.count
    guard count > 0 else { return }
    let list = stale.map { "- \($0.path.debugDescription)" }.sorted().joined(separator: "\n")
    print("Found \(count) stale snapshot\(count == 1 ? "" : "s"):\n\n\(list)")
  }
}()
