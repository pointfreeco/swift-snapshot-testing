import Diff
import Foundation

extension Strategy where A == String, B == String {
  public static let lines = Strategy(pathExtension: "txt", diffable: .lines)
}

extension String: DefaultDiffable {
  public static let defaultStrategy: SimpleStrategy<String> = .lines
}

extension Diffable where A == String {
  public static let lines = Diffable(
    to: { Data($0.utf8) },
    fro: { String(decoding: $0, as: UTF8.self) }
  ) { old, new in
    guard old != new else { return nil }
    let hunks = chunk(diff: Diff.diff(
      old.split(separator: "\n", omittingEmptySubsequences: false).map(String.init),
      new.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    ))
    let failure = hunks
      .flatMap { [$0.patchMark] + $0.lines }
      .joined(separator: "\n")
    return ("Diff: …\n\n\(failure)", [.init(string: failure, uniformTypeIdentifier: "public.patch-file")])
  }
}
