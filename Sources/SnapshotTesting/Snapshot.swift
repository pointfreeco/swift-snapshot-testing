import Foundation

public protocol Snapshot {
  associatedtype Format: Diffable
  static var snapshotPathExtension: String? { get }
  var snapshotFormat: Format { get }
}

extension Snapshot {
  public static var snapshotPathExtension: String? {
    return Format.diffablePathExtension
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
