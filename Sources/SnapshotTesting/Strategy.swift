import Foundation
import XCTest

public struct Strategy<A, B> {
  public var pathExtension: String?
  public let diffable: Diffable<B>
  public let snapshotToDiffable: (A) -> Async<B>

  public init(
    pathExtension: String?,
    diffable: Diffable<B>,
    snapshotToDiffable: @escaping (A) -> Async<B>
    ) {
    self.pathExtension = pathExtension
    self.diffable = diffable
    self.snapshotToDiffable = snapshotToDiffable
  }

  public init(
    pathExtension: String?,
    diffable: Diffable<B>,
    snapshotToDiffable: @escaping (A) -> B
    ) {
    self.init(pathExtension: pathExtension, diffable: diffable) {
      Async(value: snapshotToDiffable($0))
    }
  }

  public func asyncContramap<A0>(_ transform: @escaping (A0) -> Async<A>) -> Strategy<A0, B> {
    return Strategy<A0, B>(
      pathExtension: self.pathExtension,
      diffable: self.diffable
    ) { a0 in
      return .init { callback in
        transform(a0).run { a in
          self.snapshotToDiffable(a).run { b in
            callback(b)
          }
        }
      }
    }
  }

  public func contramap<A0>(_ transform: @escaping (A0) -> A) -> Strategy<A0, B> {
    return self.asyncContramap { Async(value: transform($0)) }
  }
}

public typealias SimpleStrategy<A> = Strategy<A, A>

extension Strategy where A == B {
  public init(pathExtension: String?, diffable: Diffable<B>) {
    self.init(
      pathExtension: pathExtension,
      diffable: diffable,
      snapshotToDiffable: { $0 }
    )
  }
}

public protocol DefaultDiffable {
  associatedtype A = Self
  associatedtype B
  static var defaultStrategy: Strategy<A, B> { get }
}
