import Foundation
import XCTest

public struct Diff {
  let failureMessage: String
  let attachments: [XCTAttachment]
  let data: Data?
}

/// The ability to compare `Value`s and convert them to and from `Data`.
public struct Diffing<Value> {
  /// Converts a value _to_ data.
  public var toData: (Value) -> Data

  /// Produces a value _from_ data.
  public var fromData: (Data) -> Value

  /// Compares two values. If the values do not match, returns a Diff.
  public var diff: (Value, Value) -> Diff?

  /// Creates a new `Diffing` on `Value`.
  ///
  /// - Parameters:
  ///   - toData: A function used to convert a value _to_ data.
  ///   - value: A value to convert into data.
  ///   - fromData: A function used to produce a value _from_ data.
  ///   - data: Data to convert into a value.
  ///   - diff: A function used to compare two values. If the values do not match, returns a Diff.
  ///   - lhs: A value to compare.
  ///   - rhs: Another value to compare.
  public init(
    toData: @escaping (_ value: Value) -> Data,
    fromData: @escaping (_ data: Data) -> Value,
    diff: @escaping (_ lhs: Value, _ rhs: Value) -> Diff?
    ) {
    self.toData = toData
    self.fromData = fromData
    self.diff = diff
  }
}
