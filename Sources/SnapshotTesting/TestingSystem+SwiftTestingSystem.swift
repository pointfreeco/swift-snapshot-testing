import Testing
@_spi(Internals) import XCTSnapshot

extension TestingSystem: SwiftTestingSystem {

  public var environment: TestingSystemEnvironment? {
    Test.current?.traits.mapIntoTestingEnvironment()
  }

  public var isRunning: Bool {
    Test.current != nil
  }

  public var isTestCompletionAttached: Bool {
    isRunning && TestCompletionNotifier.current != nil
  }

  public func record(
    message: String,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    Issue.record(
      Comment(rawValue: message),
      sourceLocation: SourceLocation(
        fileID: String(describing: fileID),
        filePath: String(describing: filePath),
        line: Int(line),
        column: Int(column)
      )
    )
  }
}

extension Array where Element == any Trait {

  func mapIntoTestingEnvironment() -> TestingSystemEnvironment {
    var environment = TestingSystemEnvironment()

    for trait in reversed() {
      switch trait {
      case let recordTrait as RecordTrait:
        if environment.recordMode == nil {
          environment.recordMode = recordTrait.recordMode
        }
      case let diffToolTrait as DiffToolTrait:
        if environment.diffTool == nil {
          environment.diffTool = diffToolTrait.diffTool
        }
      case let maxConcurrentTestsTrait as MaxConcurrentTestsTrait:
        if environment.maxConcurrentTests == nil {
          environment.maxConcurrentTests = maxConcurrentTestsTrait.maxConcurrentTests
        }
      case let platformTrait as PlatformTrait:
        if environment.platform == nil {
          environment.platform = platformTrait.platform
        }
      default:
        continue
      }

      guard
        environment.diffTool != nil,
        environment.recordMode != nil,
        environment.maxConcurrentTests != nil,
        environment.platform != nil
      else { continue }

      break
    }

    return environment
  }
}
