import Diff
import Foundation

public struct Strategy<Snapshot, Diffable> {
  public let pathExtension: String?
  public let to: (Snapshot) -> Data
  public let fro: (Data) -> Diffable
  public let diff: (Diffable, Diffable) -> String?

  public init(
    pathExtension: String? = "txt",
    to: @escaping (Snapshot) -> Data,
    fro: @escaping (Data) -> Diffable,
    diff: @escaping (Diffable, Diffable) -> String?
    ) {

    self.pathExtension = pathExtension
    self.to = to
    self.fro = fro
    self.diff = diff
  }
}

public typealias SimpleStrategy<A> = Strategy<A, A>

extension Strategy {
  static var data: SimpleStrategy<Data> {
    return .init(
      pathExtension: "txt",
      to: { $0 },
      fro: { $0 }
    ) { old, new in
      old == new ? nil : "Expected \(new) to match \(old)"
    }
  }

  static var string: SimpleStrategy<String> {
    return .init(
      pathExtension: "txt",
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
      return "Diff: …\n\n\(failure)"
    }
  }
}

public protocol Diffable {
  associatedtype Snapshot = Self
  associatedtype Diffable
  static var defaultStrategy: Strategy<Snapshot, Diffable> { get }
}

extension Data: Diffable {
  public static let defaultStrategy: SimpleStrategy<Data> = .data
}

extension String: Diffable {
  public static let defaultStrategy: SimpleStrategy<String> = .string
}
