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

  /// Transforms a strategy on `Value`s into a strategy on `Root`s through a function `(Root) -> Async<Value>`.
  ///
  /// - Parameters:
  ///   - transform: A transform function from `Root` into `Async<Value>`.
  ///   - otherValue: A value to be transformed.
  public func asyncPullback<Root>(_ transform: @escaping (_ otherValue: Root) -> Async<Value>) -> Snapshotting<Root, Format> {
    return Snapshotting<Root, Format>(
      pathExtension: self.pathExtension,
      diffing: self.diffing
    ) { root in
      return .init { callback in
        transform(root).run { value in
          self.snapshot(value).run { snapshot in
            callback(snapshot)
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
  public func pullback<Root>(_ transform: @escaping (_ otherValue: Root) -> Value) -> Snapshotting<Root, Format> {
    return self.asyncPullback { root in Async(value: transform(root)) }
  }
}

/// A snapshot strategy where the type being snapshot is also a diffable type.
public typealias SimplySnapshotting<Format> = Snapshotting<Format, Format>

extension Snapshotting where Value == Format {
  public init(pathExtension: String?, diffing: Diffing<Format>) {
    self.init(
      pathExtension: pathExtension,
      diffing: diffing,
      snapshot: { $0 }
    )
  }
}
