import Either
import Prelude
import Foundation

struct Environment {
  public static var current = Environment()

  var diffTool: String? = nil
  var isRecording = false
  var isTrackingPendingSnapshots = false
  var pendingSnapshots: [String: Set<String>] = [:]
}

internal let print = IO.wrap <| { Swift.print($0) }

internal let createDirectory = IO.wrap <<< Either.wrap
  <| { try FileManager.default.createDirectory(at: $0, withIntermediateDirectories: true, attributes: nil) }

internal let contentsOfDirectory = IO.wrap <<< Either.wrap <| {
  try FileManager.default
    .contentsOfDirectory(at: $0, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
}

internal let fileExists = IO.wrap { FileManager.default.fileExists(atPath: $0) }

internal func write(to url: URL) -> (Data) -> IO<Either<Error, ()>> {
  return IO.wrap <<< Either.wrap <| { try $0.write(to: url) }
}

internal let contentsOf = IO.wrap <<< Either.wrap <| { try Data(contentsOf: $0) }
