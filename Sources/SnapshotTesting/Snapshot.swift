import Foundation

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

extension Data: Snapshot {
  public var snapshotFormat: Data {
    return self
  }
}

extension String: Snapshot {
  public var snapshotFormat: String {
    return self
  }
}
