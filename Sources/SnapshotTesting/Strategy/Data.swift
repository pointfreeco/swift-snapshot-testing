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

extension Strategy {
  static var data: SimpleStrategy<Data> {
    return .init(
      pathExtension: nil,
      diffable: .init(to: { $0 }, fro: { $0 }) { old, new in
        guard old != new else { return nil }
        return ("Expected \(new) to match \(old)", [])
      }
    )
  }
}

extension Data: DefaultDiffable {
  public static let defaultStrategy: SimpleStrategy<Data> = .data
}
