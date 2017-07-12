import Either
import Prelude
import XCTest

public var diffTool: String? = nil
public var recording = false

public func record(while body: () -> Void) {
  recording = true
  defer { recording = false }
  body()
}

public func assertSnapshot<S: Snapshot>(
  matching snapshot: S,
  identifier: String? = nil,
  pathExtension: String? = nil,
  file: StaticString = #file,
  function: String = #function,
  line: UInt = #line)
{
  let testFileURL = file |> String.init >>> URL.init(fileURLWithPath:)

  let snapshotsDirectoryURL = testFileURL
    |> deletingLastPathComponent >>> appendingPathComponent("__Snapshots__")

  let dotPrefix: (String?) -> String = { "." + $0 } |> optional("")

  let snapshotFileName = [
    testFileURL |> deletingPathExtension >>> get(\.lastPathComponent),
    function |> dropLast(2) >>> String.init,
    identifier |> dotPrefix,
    (pathExtension ?? S.snapshotFileExtension) |> dotPrefix
  ].joined()

  let snapshotFileURL = snapshotsDirectoryURL |> appendingPathComponent(snapshotFileName)


  // IO: create snapshots dir
  let io = createDirectory(snapshotsDirectoryURL)
    .flatMap(either(pure <<< Either.left)(const <<< contentsOfDirectory <| snapshotsDirectoryURL))

  try! io.perform().unwrap()
  // IO
  let snapshotFormat = snapshot.snapshotFormat
  let snapshotData = snapshotFormat.diffableData

  snapshotFileURL |> get(\.path) >>> fileExists
  snapshotData |> write(to: snapshotFileURL)
//  guard !recording, FileManager.default.fileExists(atPath: snapshotFileURL.path) else {
//    try! snapshotData.write(to: snapshotFileURL)
//    XCTAssert(!recording, "Recorded \"\(snapshotFileURL.path)\"", file: file, line: line)
//    return
//  }

  snapshotsDirectoryURL |> contentsOfDirectory

  trackStaleSnapshots()
  let tracked: () -> Set<String> = {
    try! FileManager.default.contentsOfDirectory(atPath: snapshotsDirectoryURL.path)
      .filter { !$0.starts(with: ".") }
      .reduce([]) { $0.union([snapshotsDirectoryURL.appendingPathComponent($1).path]) }
  }
  trackedSnapshots[testFileURL, default: tracked()].remove(snapshotFileURL.path)

  snapshotFileURL |> contentsOf

  let existingData = try! Data(contentsOf: snapshotFileURL)
  let existingFormat = S.Format.fromDiffableData(existingData)
  guard !snapshotFormat.diff(from: existingFormat) else {
    let artifactsPath = ProcessInfo.processInfo.environment["SNAPSHOT_ARTIFACTS"] ?? NSTemporaryDirectory()
    let failedSnapshotFileURL = URL(fileURLWithPath: artifactsPath)
      .appendingPathComponent(snapshotFileName)
    try! snapshotData.write(to: failedSnapshotFileURL)

    let baseMessage = "\(snapshotFileURL.path.debugDescription) does not match snapshot"
    let message = diffTool
      .map {
        """
        \(baseMessage)

        \($0) \(snapshotFileURL.path.debugDescription) \(failedSnapshotFileURL.path.debugDescription)
        """
      }
      ?? baseMessage

    XCTAssertEqual(existingFormat, snapshotFormat, message, file: file, line: line)
    let attachments = snapshotFormat.diff(with: existingFormat)
    if !attachments.isEmpty {
      XCTContext.runActivity(named: "Attached failure diff") { activity in
        for attachment in attachments {
          attachment.lifetime = .deleteOnSuccess
          activity.add(attachment)
        }
      }
    }
    return
  }
}

public func assertSnapshot<S: Encodable>(
  encoding snapshot: S,
  identifier: String? = nil,
  file: StaticString = #file,
  function: String = #function,
  line: UInt = #line)
{
  let encoder = JSONEncoder()
  encoder.outputFormatting = .prettyPrinted
  let data = try! encoder.encode(snapshot)
  let string = String(data: data, encoding: .utf8)!

  assertSnapshot(
    matching: string,
    identifier: identifier,
    pathExtension: "json",
    file: file,
    function: function,
    line: line
  )
}

private var trackedSnapshots: [URL: Set<String>] = [:]
private var trackingStaleSnapshots = false

private func trackStaleSnapshots() {
  if !trackingStaleSnapshots {
    defer { trackingStaleSnapshots = true }
    atexit {
      let stale = trackedSnapshots.flatMap { $0.value }
      let staleCount = stale.count
      let staleList = stale.map { "  - \($0.debugDescription)" }.sorted().joined(separator: "\n")
      print(
        """

        Found \(staleCount) stale snapshot\(staleCount == 1 ? "" : "s"):

        \(staleList)


        """
      )
    }
  }
}
