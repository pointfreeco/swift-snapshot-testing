import Foundation
import XCTest

extension Snapshotting where Value == String, Format == String {
  /// A snapshot strategy for comparing strings based on equality.
  public static let lines = Snapshotting(pathExtension: "txt", diffing: .lines)
  
  /// A snapshot strategy for comparing nserror based on equality
  /// This strategy remove pointer informations from NSError in order to make them retestable
  public static let nserror: Snapshotting = Snapshotting<String, String>.lines.pullback { err -> String in
    var localErr : Substring = err[...]
    var shouldContinue = true
    while shouldContinue {
      if let hexaRange = localErr.range(of: ###"(0x[\w]{9})"###, options: .regularExpression) {
        localErr.removeSubrange(hexaRange)
      } else {
        shouldContinue = false
      }
    }
    return String(localErr)
  }
}

extension Diffing where Value == String {
  /// A line-diffing strategy for UTF-8 text.
  public static let lines = Diffing(
    toData: { Data($0.utf8) },
    fromData: { String(decoding: $0, as: UTF8.self) }
  ) { old, new in
    guard old != new else { return nil }
    let hunks = chunk(diff: SnapshotTesting.diff(
      old.split(separator: "\n", omittingEmptySubsequences: false).map(String.init),
      new.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    ))
    let failure = hunks
      .flatMap { [$0.patchMark] + $0.lines }
      .joined(separator: "\n")
    let attachment = XCTAttachment(data: Data(failure.utf8), uniformTypeIdentifier: "public.patch-file")
    return (failure, [attachment])
  }
}
