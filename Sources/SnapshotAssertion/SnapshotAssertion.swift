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
  var diffableData: Data { get }
  init(diffableData: Data)
  func diff(comparing other: Data) -> XCTAttachment?
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

  public var diffableData: Data {
    return self
  }

  public init(diffableData: Data) {
    self = diffableData
  }

  public func diff(comparing other: Data) -> XCTAttachment? {
    return nil
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

  public var diffableData: Data {
    return self.data(using: .utf8)!
  }

  public init(diffableData: Data) {
    self.init(data: diffableData, encoding: .utf8)!
  }

  public func diff(comparing other: Data) -> XCTAttachment? {
    return nil
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
  _ file: StaticString = #file,
  _ function: String = #function,
  _ line: UInt = #line)
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
    + (S.snapshotFileExtension.map { ".\($0)" } ?? "")
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

  guard existingData == snapshotData else {
    let failedSnapshotFileURL = URL(fileURLWithPath: NSTemporaryDirectory())
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

    let existingFormat = S.Format(diffableData: existingData)
    XCTAssertEqual(existingFormat, snapshotFormat, message, file: file, line: line)

    if let attachment = snapshotFormat.diff(comparing: existingData) {
      attachment.lifetime = .deleteOnSuccess
      XCTContext.runActivity(named: "Attached failure diff") { activity in activity.add(attachment) }
    }
    return
  }
}

public func record(during: () -> Void) {
  recording = true
  defer { recording = false }
  during()
}
