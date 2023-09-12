import Foundation
import XCTest

/// A type representing the ability to transform a snapshottable value into a diffable format (like text or an image) for snapshot testing.
public struct Snapshotting<Value, Format> {
  /// The path extension applied to references saved to disk.
  public var pathExtension: String?

  /// How the snapshot format is diffed and converted to and from data.
  public var diffing: Diffing<Format>

  /// How a value is transformed into a diffable snapshot format.
  public var snapshot: (@escaping () async throws -> Value) async throws -> Format

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
    snapshot: @escaping (_ value: @escaping () async throws -> Value) async throws -> Format
  ) {
    self.pathExtension = pathExtension
    self.diffing = diffing
    self.snapshot = snapshot
  }

  /// Creates a snapshot strategy.
  ///
  /// - Parameters:
  ///   - pathExtension: The path extension applied to references saved to disk.
  ///   - diffing: How to diff and convert the snapshot format to and from data.
  ///   - asyncSnapshot: An asynchronous transform function from a value into a diffable snapshot format.
  ///   - value: A value to be converted.
  @available(*, deprecated)
  public init(
    pathExtension: String?,
    diffing: Diffing<Format>,
    asyncSnapshot: @escaping (_ value: @escaping () async throws -> Value) -> Async<Format>
  ) {
    self.init(pathExtension: pathExtension, diffing: diffing) {
      await asyncSnapshot($0).run()
    }
  }

  //  @available(*, deprecated)
  //  public func snapshot(_ value: @autoclosure @escaping () throws -> Value) -> Async<Format> {
  //    .init(run: { try await self.snapshot { try value() } })
  //  }

  /// Transforms a strategy on `Value`s into a strategy on `NewValue`s through a function `(NewValue) -> Value`.
  ///
  /// This is the most important operation for transforming existing strategies into new strategies. It allows you to transform a `Snapshotting<Value, Format>` into a `Snapshotting<NewValue, Format>` by pulling it back along a function `(NewValue) -> Value`. Notice that the function must go in the direction `(NewValue) -> Value` even though we are transforming in the other direction `(Snapshotting<Value, Format>) -> Snapshotting<NewValue, Format>`.
  ///
  /// A simple example of this is to `pullback` the snapshot strategy on `UIView`s to work on `UIViewController`s:
  ///
  ///     let strategy = Snapshotting<UIView, UIImage>.image.pullback { (vc: UIViewController) in
  ///       return vc.view
  ///     }
  ///
  /// Here we took the strategy that snapshots `UIView`s as `UIImage`s and pulled it back to work on `UIViewController`s by using the function `(UIViewController) -> UIView` that simply plucks the view out of the controller.
  ///
  /// Nearly every snapshot strategy provided in this library is a pullback of some base strategy, which shows just how important this operation is.
  ///
  /// - Parameters:
  ///   - transform: A transform function from `NewValue` into `Value`.
  ///   - otherValue: A value to be transformed.
  public func pullback<NewValue>(
    _ transform: @escaping (_ otherValue: NewValue) async throws -> Value
  ) -> Snapshotting<NewValue, Format> {
    .init(
      pathExtension: self.pathExtension,
      diffing: self.diffing
    ) { (newValue: @escaping () async throws -> NewValue) in
      try await self.snapshot { try await transform(newValue()) }
    }
  }

  /// Transforms a strategy on `Value`s into a strategy on `NewValue`s through a function `(NewValue) -> Async<Value>`.
  ///
  /// See the documentation of `pullback` for a full description of how pullbacks works. This operation differs from `pullback` in that it allows you to use a transformation `(NewValue) -> Async<Value>`, which is necessary when your transformation needs to perform some asynchronous work.
  ///
  /// - Parameters:
  ///   - transform: A transform function from `NewValue` into `Async<Value>`.
  ///   - otherValue: A value to be transformed.
  @available(*, deprecated)
  public func asyncPullback<NewValue>(
    _ transform: @escaping (_ otherValue: NewValue) -> Async<Value>
  ) -> Snapshotting<NewValue, Format> {
    self.pullback { newValue in
      await transform(newValue).run()
    }
  }
}

/// A snapshot strategy where the type being snapshot is also a diffable type.
public typealias SimplySnapshotting<Format> = Snapshotting<Format, Format>

extension Snapshotting where Value == Format {
  public init(pathExtension: String?, diffing: Diffing<Format>) {
    self.init(
      pathExtension: pathExtension,
      diffing: diffing,
      snapshot: { try await $0() }
    )
  }
}
