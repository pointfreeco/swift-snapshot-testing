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

  /// Transforms a strategy on `Value`s into a strategy on `NewValue`s through a function `(NewValue) -> Async<Value>`.
  ///
  /// - Parameters:
  ///   - transform: A transform function from `NewValue` into `Async<Value>`.
  ///   - otherValue: A value to be transformed.
  public func asyncPullback<NewValue>(_ transform: @escaping (_ otherValue: NewValue) -> Async<Value>)
    -> Snapshotting<NewValue, Format> {

      return Snapshotting<NewValue, Format>(
        pathExtension: self.pathExtension,
        diffing: self.diffing
      ) { newValue in
        return .init { callback in
          transform(newValue).run { value in
            self.snapshot(value).run { snapshot in
              callback(snapshot)
            }
          }
        }
      }
  }

  /// Transforms a strategy on `Value`s into a strategy on `NewValue`s through a function `(NewValue) -> Value`.
  ///
  /// - Parameters:
  ///   - transform: A transform function from `NewValue` into `Value`.
  ///   - otherValue: A value to be transformed.
  public func pullback<NewValue>(_ transform: @escaping (_ otherValue: NewValue) -> Value) -> Snapshotting<NewValue, Format> {
    return self.asyncPullback { newValue in Async(value: transform(newValue)) }
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
