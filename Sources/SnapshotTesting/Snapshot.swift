import Diff
import Foundation
import XCTest

public struct _Snapshot<A> {
  /// If the first and second arguments differ, returns a string description of the diff and an array of
  /// `XCTAttachment` to be associated with the failure.
  let diff: (A, A) -> (String, [XCTAttachment])?

  let diffDescription: (A) -> String?
  let diffPathExtension: String?
  let pathExtension: String?
  let snapshotData: (A) -> Data
}


let standardStringSnapshot = _Snapshot<String>(
  diff: { fst, snd in

    guard fst != snd else { return nil }

    let hunks = chunk(diff: diff(
      fst.split(separator: "\n", omittingEmptySubsequences: false),
      snd.split(separator: "\n", omittingEmptySubsequences: false)
    ))
    let failure = hunks.flatMap { [$0.patchMark] + $0.lines }.joined(separator: "\n")

    return ("Diff: …\n\n\(failure)", [.init(string: failure)])

},
  diffDescription: { $0.trimmingCharacters(in: .newlines) },
  diffPathExtension: "txt",
  pathExtension: "txt",
  snapshotData: { $0.data(using: .utf8)! }
)

let standardImageSnapshot = _Snapshot<NSImage>(
  diff: NSImage.diffableDiff,
  diffDescription: { _ in nil },
  diffPathExtension: "png",
  pathExtension: "png",
  snapshotData: { $0.data(using: .utf8)! }
)



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
