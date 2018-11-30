import Foundation
import XCTest

extension Attachment {
  public init(data: Data, name: String? = nil) {
    #if !os(Linux)
    self.rawValue = XCTAttachment(data: data)
    self.rawValue.name = name
    #endif
  }
}

extension Snapshotting where Value == Data, Format == Data {
  static var data: Snapshotting {
    return .init(
      pathExtension: nil,
      diffing: .init(toData: { $0 }, fromData: { $0 }) { old, new in
        guard old != new else { return nil }
        let message = old.count == new.count
          ? "Expected data to match"
          : "Expected \(new) to match \(old)"
        return (message, [])
      }
    )
  }
}
