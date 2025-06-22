import Foundation
import Testing
@_spi(Internals) import XCTSnapshot

public struct PlatformTrait: SuiteTrait, TestTrait {
  public let isRecursive = true
  let platform: String
}

extension Trait where Self == PlatformTrait {

  public static func platform(_ platform: String?) -> Self {
    .init(platform: platform ?? "")
  }
}
