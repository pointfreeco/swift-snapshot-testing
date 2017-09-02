import Diff
import Foundation
import XCTest

public protocol Diffable {
  static var diffablePathExtension: String? { get }
  static func diffableDiff(_ fst: Self, _ snd: Self) -> (String, [XCTAttachment])?
  static func fromDiffableData(_ diffableData: Data) -> Self
  var diffableData: Data { get }
  var diffableDescription: String? { get }
}

extension Data: Diffable {
  public static let diffablePathExtension = String?.none

  public static func diffableDiff(_ fst: Data, _ snd: Data) -> (String, [XCTAttachment])? {
    guard fst != snd else { return nil }

    return ("Expected \(snd) to match \(fst)", [])
  }

  public static func fromDiffableData(_ diffableData: Data) -> Data {
    return diffableData
  }

  public var diffableData: Data {
    return self
  }

  public var diffableDescription: String? {
    return nil
  }
}

extension String: Diffable {
  public static let diffablePathExtension = String?.some("txt")

  public static func diffableDiff(_ fst: String, _ snd: String) -> (String, [XCTAttachment])? {
    guard fst != snd else { return nil }

    let hunks = chunk(diff: diff(fst.split(separator: "\n"), snd.split(separator: "\n")))
    let failure = hunks.flatMap { [$0.patchMark] + $0.lines }.joined(separator: "\n")

    return ("Diff: …\n\n\(failure)", [.init(string: failure)])
  }

  public static func fromDiffableData(_ diffableData: Data) -> String {
    return String(data: diffableData, encoding: .utf8)!
  }

  public var diffableData: Data {
    return self.data(using: .utf8)!
  }

  public var diffableDescription: String? {
    return self.trimmingCharacters(in: .newlines)
  }
}
