import Foundation
import XCTest

/// A type representing the ability to transform a snapshottable value into a diffable format (like text or an image) for snapshot testing.
public struct Snapshotting<Value, Format> {
  /// The path extension applied to references saved to disk.
  public var pathExtension: String?

  /// How the snapshot format is diffed and converted to and from data.
  public let diffing: Diffing<Format>

  /// How a value is transformed into a diffable snapshot format.
  public let snapshot: (Value) -> Async<Format>

  /// Creates a snapshot strategy.
  ///
  /// - Parameters:
  ///   - pathExtension: The path extension applied to references saved to disk.
  ///   - diffing: How to diff and convert the snapshot format to and from data.
  ///   - snapshot: An asynchronous transform function from a value into a diffable snapshot format.
  ///   - value: A value to be converted.
  public init(
    pathExtension: String?,
    diffing: Diffing<Format>,
    asyncSnapshot: @escaping (_ value: Value) -> Async<Format>
    ) {
    self.pathExtension = pathExtension
    self.diffing = diffing
    self.snapshot = asyncSnapshot
  }

  /// Creates a snapshot strategy.
  ///
  /// - Parameters:
  ///   - pathExtension: The path extension applied to references saved to disk.
  ///   - diffing: How to diff and convert the snapshot format to and from data.
  ///   - snapshot: A transform function from a value into a diffable snapshot format.
  ///   - value: A snapshot value to be converted.
  public init(
    pathExtension: String?,
    diffing: Diffing<Format>,
    snapshot: @escaping (_ value: Value) -> Format
    ) {
    self.init(pathExtension: pathExtension, diffing: diffing) {
      Async(value: snapshot($0))
    }
  }

  /// Transforms a strategy on `Value`s into a strategy on `A`s through a function `(A) -> Async<Value>`.
  ///
  /// - Parameters:
  ///   - transform: A transform function from `A` into `Async<Value>`.
  ///   - otherValue: A value to be transformed.
  public func asyncPullback<A>(_ transform: @escaping (_ otherValue: A) -> Async<Value>) -> Snapshotting<A, Format> {
    return Snapshotting<A, Format>(
      pathExtension: self.pathExtension,
      diffing: self.diffing
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
  public func pullback<A>(_ transform: @escaping (_ otherValue: A) -> Value) -> Snapshotting<A, Format> {
    return self.asyncPullback { Async(value: transform($0)) }
  }
}

/// A snapshot strategy where the type being snapshot is also a diffable type.
public typealias SimplySnapshotting<A> = Snapshotting<A, A>

extension Snapshotting where Value == Format {
  public init(pathExtension: String?, diffing: Diffing<Format>) {
    self.init(
      pathExtension: pathExtension,
      diffing: diffing,
      snapshot: { $0 }
    )
  }
}
