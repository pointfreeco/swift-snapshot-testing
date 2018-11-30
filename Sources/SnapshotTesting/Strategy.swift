import Foundation
import XCTest

/// A type representing the ability to transform a value into a diffable format (like text or an image) for snapshot testing.
public struct Strategy<Snapshottable, Format> {
  /// The path extension applied to references saved to disk.
  public var pathExtension: String?

  /// How the snapshot format is diffed and converted to and from data.
  public let diffable: Diffable<Format>

  /// How a value is transformed into a diffable snapshot format.
  public let snapshot: (Snapshottable) -> Async<Format>

  /// Creates a snapshot strategy.
  ///
  /// - Parameters:
  ///   - pathExtension: The path extension applied to references saved to disk.
  ///   - diffable: How to diff and convert the snapshot format to and from data.
  ///   - snapshot: An asynchronous transform function from a value into a diffable snapshot format.
  ///   - value: A value to be converted.
  public init(
    pathExtension: String?,
    diffable: Diffable<Format>,
    snapshot: @escaping (_ value: Snapshottable) -> Async<Format>
    ) {
    self.pathExtension = pathExtension
    self.diffable = diffable
    self.snapshot = snapshot
  }

  /// Creates a snapshot strategy.
  ///
  /// - Parameters:
  ///   - pathExtension: The path extension applied to references saved to disk.
  ///   - diffable: How to diff and convert the snapshot format to and from data.
  ///   - snapshot: A transform function from a value into a diffable snapshot format.
  ///   - value: A snapshot value to be converted.
  public init(
    pathExtension: String?,
    diffable: Diffable<Format>,
    snapshot: @escaping (_ value: Snapshottable) -> Format
    ) {
    self.init(pathExtension: pathExtension, diffable: diffable) {
      Async(value: snapshot($0))
    }
  }

  /// Transforms a strategy on `Value`s into a strategy on `A`s through a function `(A) -> Async<Value>`.
  ///
  /// - Parameters:
  ///   - transform: A transform function from `A` into `Async<Value>`.
  ///   - otherValue: A value to be transformed.
  public func asyncPullback<A>(_ transform: @escaping (_ otherValue: A) -> Async<Snapshottable>) -> Strategy<A, Format> {
    return Strategy<A, Format>(
      pathExtension: self.pathExtension,
      diffable: self.diffable
    ) { a0 in
      return .init { callback in
        transform(a0).run { a in
          self.snapshot(a).run { b in
            callback(b)
          }
        }
      }
    }
  }

  /// Transforms a strategy on `Value`s into a strategy on `A`s through a function `(A) -> Value`.
  ///
  /// - Parameters:
  ///   - transform: A transform function from `A` into `Value`.
  ///   - otherValue: A value to be transformed.
  public func pullback<A>(_ transform: @escaping (_ otherValue: A) -> Snapshottable) -> Strategy<A, Format> {
    return self.asyncPullback { Async(value: transform($0)) }
  }
}

/// A snapshot strategy where the type being snapshot is also a diffable type.
public typealias SimpleStrategy<A> = Strategy<A, A>

extension Strategy where Snapshottable == Format {
  public init(pathExtension: String?, diffable: Diffable<Format>) {
    self.init(
      pathExtension: pathExtension,
      diffable: diffable,
      snapshot: { $0 }
    )
  }
}
