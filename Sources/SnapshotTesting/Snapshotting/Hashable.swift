import Foundation

extension Snapshotting where Format: Hashable {

  /// A snapshot strategy to compare hashes after transforming a `Value` to an `Hashable` `Format`.
  ///
  /// - Parameters:
  ///   - transform: Closure transforming a `Value` to an `Hashable` `Format`.
  public static func hash(
    from transform: @escaping (Value) -> Format
    )
    -> Snapshotting<Value, Int> {
      return SimplySnapshotting.int.pullback {
        transform($0).hashValue
      }
  }

  /// A snapshot strategy to compare hashes after transforming a `Value` to an `Async` of `Hashable` `Format`.
  ///
  /// - Parameters:
  ///   - transform: Closure transforming a `Value` to an `Async` of `Hashable` `Format`.
  public static func hash(
    from asyncTransform: @escaping (Value) -> Async<Format>
    )
    -> Snapshotting<Value, Int> {
      return SimplySnapshotting.int.asyncPullback {
        asyncTransform($0).map { $0.hashValue }
      }
  }

  /// A snapshot strategy to compare hashes from a `Value` `Snapshotting` strategy using `Hashable` `Format`
  ///
  /// - Parameters:
  ///   - Snapshotting: `Value` `Snapshotting` strategy using `Hashable` `Format`
  public static func hash(
    from preHashSnapshotting: Snapshotting<Value, Format>
    )
    -> Snapshotting<Value, Int> {
      return hash(from: preHashSnapshotting.snapshot)
  }
}
extension Snapshotting where Value: Hashable {

  /// A snapshot strategy to compare hashes of `Hashable` `Value`
  public static var hash: Snapshotting<Value, Int> {
    return SimplySnapshotting<Value>.hash(from: { $0 })
  }
}
