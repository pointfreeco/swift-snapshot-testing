import Foundation
import XCTest

/// The ability to compare `Value`s and convert them to and from `Data`.
public struct Diffing<Value> {
  /// Converts a value _to_ data, throwing an error that explains a value that can't be converted.
  ///
  /// A thrown error's `localizedDescription` becomes the test failure message, so conform it to
  /// `LocalizedError`.
  public var toData: (Value) throws -> Data

  /// Produces a value _from_ data, throwing an error that explains data that isn't a valid value.
  ///
  /// A thrown error is reported after the reference's path, with its `LocalizedError` description,
  /// or its full description otherwise.
  public var fromData: (Data) throws -> Value

  /// Compares two values. If the values do not match, returns a failure message and artifacts
  /// describing the failure.
  @available(*, deprecated, message: "Use 'diffV2'")
  public var diff: (Value, Value) -> (String, [XCTAttachment])? {
    @storageRestrictions(initializes: diffV2)
    init(diff) {
      self.diffV2 = {
        guard let (message, attachments) = diff($0, $1)
        else {
          return nil
        }
        return (message, attachments.map(DiffAttachment.xcTest))
      }
    }
    get {
      {
        guard let (message, attachments) = diffV2($0, $1)
        else { return nil }
        return (
          message,
          attachments.compactMap {
            guard case .xcTest(let attachment) = $0 else { return nil }
            return attachment
          }
        )
      }
    }
    set {
      diffV2 = {
        guard let (message, attachments) = newValue($0, $1)
        else {
          return nil
        }
        return (message, attachments.map(DiffAttachment.xcTest))
      }
    }
  }

  /// Compares two values. If the values do not match, returns a failure message and artifacts
  /// describing the failure.
  public var diffV2: (Value, Value) -> (String, [DiffAttachment])?

  /// Creates a new `Diffing` on `Value`.
  ///
  /// - Parameters:
  ///   - toData: A function used to convert a value _to_ data, throwing an error that explains a
  ///     value that can't be converted.
  ///   - fromData: A function used to produce a value _from_ data, throwing an error that explains
  ///     data that isn't a valid value.
  ///   - diff: A function used to compare two values. If the values do not match, returns a failure
  ///     message and artifacts describing the failure.
  @available(*, deprecated, message: "Use 'Diffing.diff'")
  public init(
    toData: @escaping (_ value: Value) throws -> Data,
    fromData: @escaping (_ data: Data) throws -> Value,
    diff: @escaping (_ lhs: Value, _ rhs: Value) -> (String, [XCTAttachment])?
  ) {
    self.toData = toData
    self.fromData = fromData
    self.diff = diff
  }

  private init(
    toData: @escaping (Value) throws -> Data,
    fromData: @escaping (Data) throws -> Value,
    diffV2: @escaping (Value, Value) -> (String, [DiffAttachment])?
  ) {
    self.toData = toData
    self.fromData = fromData
    self.diffV2 = diffV2
  }

  /// Creates a new `Diffing` on `Value`.
  ///
  /// - Parameters:
  ///   - toData: A function used to convert a value _to_ data. See ``toData``.
  ///   - fromData: A function used to produce a value _from_ data. See ``fromData``.
  ///   - diffV2: A function used to compare two values. If the values do not match, returns a
  ///     failure message and attachments describing the failure.
  public static func diff(
    toData: @escaping (_ value: Value) throws -> Data,
    fromData: @escaping (_ data: Data) throws -> Value,
    diffV2: @escaping (_ lhs: Value, _ rhs: Value) -> (String, [DiffAttachment])?
  ) -> Self {
    Diffing(toData: toData, fromData: fromData, diffV2: diffV2)
  }
}

public enum DiffAttachment {
  @available(*, deprecated)
  case xcTest(XCTAttachment)
  case data(Data, name: String)
}
