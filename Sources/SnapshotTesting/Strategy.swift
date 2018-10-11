import Foundation
import XCTest

public struct Parallel<A> {
  public let run: (@escaping (A) -> Void) -> Void

  public init(run: @escaping (@escaping (A) -> Void) -> Void) {
    self.run = run
  }

  public init(value: A) {
    self.init { callback in callback(value) }
  }

  public func map<B>(_ transform: @escaping (A) -> B) -> Parallel<B> {
    return .init { callback in
      self.run { a in
        callback(transform(a))
      }
    }
  }
}

public struct Strategy<A, B> {
  public let pathExtension: String?
  public let diffable: Diffable<B>
  public let snapshotToDiffable: (A) -> Parallel<B?>

  public init(
    pathExtension: String?,
    diffable: Diffable<B>,
    snapshotToDiffable: @escaping (A) -> Parallel<B?>
    ) {
    self.pathExtension = pathExtension
    self.diffable = diffable
    self.snapshotToDiffable = snapshotToDiffable
  }

  public init(
    pathExtension: String?,
    diffable: Diffable<B>,
    snapshotToDiffable: @escaping (A) -> B?
    ) {
    self.init(pathExtension: pathExtension, diffable: diffable) {
      Parallel(value: snapshotToDiffable($0))
    }
  }

  public func preAsync<A0>(_ transform: @escaping (A0) -> Parallel<A?>) -> Strategy<A0, B> {
    return Strategy<A0, B>(
      pathExtension: self.pathExtension,
      diffable: self.diffable
    ) { a0 in
      return .init { callback in
        transform(a0).run { a in
          guard let a = a else {
            callback(nil)
            return
          }
          self.snapshotToDiffable(a).run { b in
            callback(b)
          }
        }
      }
    }
  }

  public func pre<A0>(_ transform: @escaping (A0) -> A?) -> Strategy<A0, B> {
    return self.preAsync { Parallel(value: transform($0)) }
  }

  public func post(_ transform: @escaping (B) -> B) -> Strategy {
    return .init(
      pathExtension: self.pathExtension,
      diffable: self.diffable
    ) { a in
      return .init { callback in
        self.snapshotToDiffable(a).run { b in
          callback(b.map(transform))
        }
      }
    }
  }
}

public typealias SimpleStrategy<A> = Strategy<A, A>

extension Strategy where A == B {
  public init(pathExtension: String?, diffable: Diffable<B>) {
    self.init(
      pathExtension: pathExtension,
      diffable: diffable,
      snapshotToDiffable: Parallel.init(value:)
    )
  }
}

public protocol DefaultDiffable {
  associatedtype A = Self
  associatedtype B
  static var defaultStrategy: Strategy<A, B> { get }
}
