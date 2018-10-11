import Diff
import Foundation

extension Strategy {
  public static var string: SimpleStrategy<String> {
    return .init(
      pathExtension: "txt",
      diffable: .init(to: { Data($0.utf8) }, fro: { String(data: $0, encoding: .utf8) }) { old, new in
        guard old != new else { return nil }
        let hunks = chunk(diff: Diff.diff(
          old.split(separator: "\n", omittingEmptySubsequences: false).map(String.init),
          new.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        ))
        let failure = hunks
          .flatMap { [$0.patchMark] + $0.lines }
          .joined(separator: "\n")
        return ("Diff: …\n\n\(failure)", [.init(string: failure)])
      }
    )
  }
}

extension String: DefaultDiffable {
  public static let defaultStrategy: SimpleStrategy<String> = .string
}
