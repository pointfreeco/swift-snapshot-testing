import XCTest

public var diffTool: String? = nil
public var recording = false

private var snapshots: [String: [String: ()]] = [:]
private var attached = false
private func attach() {
  if !attached {
    defer { attached = true }
    atexit {
      let stale = snapshots.flatMap { $0.value.keys }
      let staleList = stale.map { "  - \($0.debugDescription)" }.joined(separator: "\n")
      print(
        """

        \(stale.count) stale snapshots:

        \(staleList)
        """
      )
    }
  }
}

public protocol Diffable: Equatable {
  static var diffableFileExtension: String? { get }
  static func fromDiffableData(_ data: Data) -> Self
  var diffableData: Data { get }
  func diff(from other: Self) -> Bool
  func diff(with other: Self) -> [XCTAttachment]
}

extension Diffable {
  public func diff(from other: Self) -> Bool {
    return self.diffableData != other.diffableData
  }
}

public protocol Snapshot {
  associatedtype Format: Diffable
  static var snapshotFileExtension: String? { get }
  var snapshotFormat: Format { get }
}

extension Snapshot {
  public static var snapshotFileExtension: String? {
    return Format.diffableFileExtension
  }
}

extension Data: Diffable {
  public static var diffableFileExtension: String? {
    return nil
  }

  public static func fromDiffableData(_ data: Data) -> Data {
    return data
  }

  public var diffableData: Data {
    return self
  }

  public func diff(with other: Data) -> [XCTAttachment] {
    return []
  }
}

extension Data: Snapshot {
  public var snapshotFormat: Data {
    return self
  }
}

extension String: Diffable {
  public static var diffableFileExtension: String? {
    return "txt"
  }

  public static func fromDiffableData(_ data: Data) -> String {
    return String(data: data, encoding: .utf8)!
  }

  public var diffableData: Data {
    return self.data(using: .utf8)!
  }

  public func diff(with other: String) -> [XCTAttachment] {
    return []
  }
}

extension String: Snapshot {
  public var snapshotFormat: String {
    return self
  }
}

public func assertSnapshot<S: Snapshot>(
  matching snapshot: S,
  identifier: String? = nil,
  pathExtension: String? = nil,
  file: StaticString = #file,
  function: String = #function,
  line: UInt = #line)
{
  let filePath = "\(file)"
  let testFileURL = URL(fileURLWithPath: filePath)
  let snapshotsDirectoryURL = testFileURL.deletingLastPathComponent()
    .appendingPathComponent("__Snapshots__")

  let fileManager = FileManager.default
  try! fileManager
    .createDirectory(at: snapshotsDirectoryURL, withIntermediateDirectories: true, attributes: nil)

  let snapshotFileName = testFileURL.deletingPathExtension().lastPathComponent
    + ".\(function.dropLast(2))"
    + (identifier.map { ".\($0)" } ?? "")
    + ((pathExtension ?? S.snapshotFileExtension).map { ".\($0)" } ?? "")
  let snapshotFileURL = snapshotsDirectoryURL.appendingPathComponent(snapshotFileName)
  let snapshotFormat = snapshot.snapshotFormat
  let snapshotData = snapshotFormat.diffableData

  attach()
  let tracked: () -> [String: ()] = {
    try! fileManager.contentsOfDirectory(atPath: snapshotsDirectoryURL.path)
      .filter { !$0.starts(with: ".") }
      .reduce([:]) {
        var copy = $0
        copy[snapshotsDirectoryURL.appendingPathComponent($1).path] = ()
        return copy
    }
  }
  snapshots[filePath, default: tracked()][snapshotFileURL.path] = nil

  guard !recording, fileManager.fileExists(atPath: snapshotFileURL.path) else {
    try! snapshotData.write(to: snapshotFileURL)
    XCTAssert(!recording, "Recorded \"\(snapshotFileURL.path)\"", file: file, line: line)
    return
  }

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

public func record(during: () -> Void) {
  recording = true
  defer { recording = false }
  during()
}
