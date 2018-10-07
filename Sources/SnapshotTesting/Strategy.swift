import Diff
import Foundation

public struct _Diffable<D> {
  public let to: (D) -> Data
  public let fro: (Data) -> D
  public let diff: (D, D) -> String?
}

public struct Parallel<A> {
  let run: (@escaping (A) -> Void) -> Void

  static func fish<B, C>(_ lhs: @escaping (A) -> Parallel<B>, _ rhs: @escaping (B) -> Parallel<C>) -> (A) -> Parallel<C> {
    return { a in
      return .init { callback in
        lhs(a).run { b in
          rhs(b).run { c in
            callback(c)
          }
        }
      }
    }
  }

  static func pure(_ a: A) -> Parallel {
    return Parallel { callback in callback(a) }
  }
}

public struct _Strategy<S, D> {
  public let pathExtension: String?
  public let diffable: _Diffable<D>
  public let s2d: (S) -> Parallel<D>
  // (S, (D) -> Void) -> Void
  // (S) -> (D -> Void) -> Void
  // (S) -> Cont<D, Void>

  // Cont<R, A> = ((R) -> A) -> A

  //


  func transform<T>(_ f: @escaping (T) -> ((S) -> Void) -> Void) -> _Strategy<T, D> {
  }

  func transform<T>(_ f: @escaping (T) -> Parallel<S>) -> _Strategy<T, D> {
    return _Strategy<T, D>(
      pathExtension: self.pathExtension,
      diffable: self.diffable,
      s2d: Parallel.fish(f, self.s2d)
    )
  }
}


public struct Strategy<Snapshot, Diffable> {
  public let pathExtension: String?
  public let to: (Snapshot) -> Data
  public let fro: (Data) -> Diffable
  public let diff: (Diffable, Diffable) -> String?

  func contramap<S>(_ f: @escaping (S) -> Snapshot) -> Strategy<S, Diffable> {
    return .init(
      pathExtension: self.pathExtension,
      to: { self.to(f($0)) },
      fro: self.fro,
      diff: self.diff
    )
  }

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
