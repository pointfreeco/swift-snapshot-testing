import Foundation
import Testing
@_spi(Internals) import XCTSnapshot

public struct RecordTrait: SuiteTrait, TestTrait {
  public let isRecursive = true
  let recordMode: RecordMode
}

extension Trait where Self == RecordTrait {

  public static func record(_ recordMode: RecordMode) -> Self {
    .init(recordMode: recordMode)
  }
}
