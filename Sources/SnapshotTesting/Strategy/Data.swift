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

extension Strategy where Snapshottable == Data, Format == Data {
  static var data: Strategy {
    return .init(
      pathExtension: nil,
      diffable: .init(to: { $0 }, fro: { $0 }) { old, new in
        guard old != new else { return nil }
        let message = old.count == new.count
          ? "Expected data to match"
          : "Expected \(new) to match \(old)"
        return (message, [])
      }
    )
  }
}

extension Data: DefaultSnapshottable {
  public static let defaultStrategy: SimpleStrategy = .data
}
