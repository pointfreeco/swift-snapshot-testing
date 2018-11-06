import Foundation
import XCTest

extension Attachment {
  public init(data: Data, name: String? = nil) {
    #if Xcode
    self.rawValue = XCTAttachment(data: data)
    self.rawValue.name = name
    #endif
  }
}

extension Strategy where A == Data, B == Data {
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

extension Data: DefaultDiffable {
  public static let defaultStrategy: SimpleStrategy = .data
}
