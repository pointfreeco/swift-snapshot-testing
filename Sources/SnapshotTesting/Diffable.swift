import Foundation
import XCTest

public protocol Diffable: Equatable {
  static var diffableFileExtension: String? { get }
  static func fromDiffableData(_ data: Data) -> Self
  var diffableData: Data { get }
  func diff(from other: Self) -> Bool
  func diff(with other: Self) -> [XCTAttachment]
}

extension Diffable {
  public func diff(from other: Self) -> Bool {
    return self.diffableData != other.diffableData
  }
}

extension Data: Diffable {
  public static var diffableFileExtension: String? {
    return nil
  }

  public static func fromDiffableData(_ data: Data) -> Data {
    return data
  }

  public var diffableData: Data {
    return self
  }

  public func diff(with other: Data) -> [XCTAttachment] {
    return []
  }
}

extension String: Diffable {
  public static var diffableFileExtension: String? {
    return "txt"
  }

  public static func fromDiffableData(_ data: Data) -> String {
    return String(data: data, encoding: .utf8)!
  }

  public var diffableData: Data {
    return self.data(using: .utf8)!
  }

  public func diff(with other: String) -> [XCTAttachment] {
    return []
  }
}
