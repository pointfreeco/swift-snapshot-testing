import XCTest

var diffTool: String? = nil

public protocol Diffable {
  static var diffableFileExtension: String? { get }
  var diffableData: Data { get }
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
  let testFileURL = URL(fileURLWithPath: "\(file)")
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

  guard fileManager.fileExists(atPath: snapshotFileURL.path) else {
    try! snapshotData.write(to: snapshotFileURL)
    return
  }

  let existingData = try! Data(contentsOf: snapshotFileURL)

  guard existingData == snapshotData else {
    let failedSnapshotFileURL = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent(snapshotFileName)
    try! snapshotData.write(to: failedSnapshotFileURL)

    let baseMessage = "\(snapshotFileURL.path) does not match snapshot"
    let message = diffTool
      .map { "\(baseMessage)\n\n\($0) \"\(snapshotFileURL.path)\" \"\(failedSnapshotFileURL.path)\"" }
      ?? baseMessage

    XCTAssert(false, message, file: file, line: line)

    if let attachment = snapshotFormat.diff(comparing: existingData) {
      attachment.lifetime = .deleteOnSuccess
      XCTContext.runActivity(named: "Attached failure diff") { activity in activity.add(attachment) }
    }
    return
  }
}
