import Foundation
import XCTest

extension Snapshotting where Value == Int, Format == Int {
  /// A snapshot strategy to compare integers based on equality.
  public static let int = Snapshotting(pathExtension: nil, diffing: .int)
}

extension Diffing where Value == Int {

  /// An integer-diffing strategy
  public static let int = Diffing(
    toData: { $0.data },
    fromData: { $0.intValue }
  ) { old, new in
    guard old != new else { return nil }
    let failure = "\(old) - \(new)"
    let attachment = XCTAttachment(
      data: Data(failure.utf8),
      uniformTypeIdentifier: "public.patch-file"
    )
    return (failure, [attachment])
  }
}

private extension Data {

  /// Integer value from data, assumes the data comes from an int value,
  /// therefore only considers the first binded value integer
  var intValue: Int {
    return withUnsafeBytes { $0.bindMemory(to: Int.self).first } ?? 0
  }
}

private extension Int {

  var data: Data {
    var value = self
    return Data(
      bytes: &value,
      count: MemoryLayout.size(ofValue: value)
    )
  }
}
