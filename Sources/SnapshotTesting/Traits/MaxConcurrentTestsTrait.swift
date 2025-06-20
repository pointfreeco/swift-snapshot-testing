import Testing
import Foundation
@_spi(Internals) import XCTSnapshot

public struct MaxConcurrentTestsTrait: SuiteTrait, TestTrait {
  public let isRecursive = true
  let maxConcurrentTests: Int
}

extension Trait where Self == MaxConcurrentTestsTrait {

  public static func maxConcurrentTests(_ maxConcurrentTests: Int) -> Self {
    .init(maxConcurrentTests: maxConcurrentTests)
  }
}
