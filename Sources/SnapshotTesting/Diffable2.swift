import Diff
import Foundation

struct Diffable2<A> {
  let pathExtension: String?
  let diff: (A, A) -> String?
  let from: (Data) -> A
  let to: (A) -> Data
}

let stringDiffable = Diffable2<String>.init(
  pathExtension: "txt",
  diff: { fst, snd in

    guard fst != snd else { return nil }

    let hunks = chunk(diff: diff(
      fst.split(separator: "\n", omittingEmptySubsequences: false).map(String.init),
      snd.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    ))
    let failure = hunks.flatMap { [$0.patchMark] + $0.lines }
      .prefix(5)
      .map { $0.prefix(80) }
      .joined(separator: "\n")

    return "Diff: …\n\n\(failure)"

},
  from: { String.init(decoding: $0, as: UTF8.self) },
  to: { Data($0.utf8) }
)

