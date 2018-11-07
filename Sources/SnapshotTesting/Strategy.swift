import Foundation
import XCTest

public struct Strategy<Snapshottable, Format> {
  public var pathExtension: String?
  public let diffable: Diffable<Format>
  public let snapshotToDiffable: (Snapshottable) -> Async<Format>

  public init(
    pathExtension: String?,
    diffable: Diffable<Format>,
    snapshotToDiffable: @escaping (Snapshottable) -> Async<Format>
    ) {
    self.pathExtension = pathExtension
    self.diffable = diffable
    self.snapshotToDiffable = snapshotToDiffable
  }

  public init(
    pathExtension: String?,
    diffable: Diffable<Format>,
    snapshotToDiffable: @escaping (Snapshottable) -> Format
    ) {
    self.init(pathExtension: pathExtension, diffable: diffable) {
      Async(value: snapshotToDiffable($0))
    }
  }

  public func asyncPullback<A0>(_ transform: @escaping (A0) -> Async<Snapshottable>) -> Strategy<A0, Format> {
    return Strategy<A0, Format>(
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

  public func pullback<A0>(_ transform: @escaping (A0) -> Snapshottable) -> Strategy<A0, Format> {
    return self.asyncPullback { Async(value: transform($0)) }
  }
}

public typealias SimpleStrategy<A> = Strategy<A, A>

extension Strategy where Snapshottable == Format {
  public init(pathExtension: String?, diffable: Diffable<Format>) {
    self.init(
      pathExtension: pathExtension,
      diffable: diffable,
      snapshotToDiffable: { $0 }
    )
  }
}

public protocol DefaultSnapshottable {
  associatedtype Snapshottable = Self
  associatedtype Format
  static var defaultStrategy: Strategy<Snapshottable, Format> { get }
}
