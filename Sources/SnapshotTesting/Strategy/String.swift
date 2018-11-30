import Foundation

extension Strategy where Snapshottable == String, Format == String {
  /// A snapshot strategy for comparing strings based on equality.
  public static let lines = Strategy(pathExtension: "txt", diffable: .lines)
}

extension Diffable where Value == String {
  /// A line-diffing strategy for UTF-8 text.
  public static let lines = Diffable(
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
    return ("Diff: …\n\n\(failure)", [.init(string: failure, uniformTypeIdentifier: "public.patch-file")])
  }
}
