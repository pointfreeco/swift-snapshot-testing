import Foundation
import Testing
@_spi(Internals) import XCTSnapshot

public struct DiffToolTrait: SuiteTrait, TestTrait {
  public let isRecursive = true
  let diffTool: DiffTool
}

extension Trait where Self == DiffToolTrait {

  public static func diffTool(_ diffTool: DiffTool) -> Self {
    .init(diffTool: diffTool)
  }
}
