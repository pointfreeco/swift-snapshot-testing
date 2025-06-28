import XCTest

@_spi(Internals)
public struct TestingSystemEnvironment {

    public var recordMode: RecordMode?
    public var diffTool: DiffTool?
    public var maxConcurrentTests: Int?
    public var platform: String?

    public init(
        recordMode: RecordMode? = nil,
        diffTool: DiffTool? = nil,
        maxConcurrentTests: Int? = nil,
        platform: String? = nil
    ) {
        self.recordMode = recordMode
        self.diffTool = diffTool
        self.maxConcurrentTests = maxConcurrentTests
        self.platform = platform
    }
}

@_spi(Internals)
public protocol SwiftTestingSystem {

    var environment: TestingSystemEnvironment? { get }

    var isRunning: Bool { get }

    var isTestCompletionAttached: Bool { get }

    func record(
        message: String,
        fileID: StaticString,
        filePath: StaticString,
        line: UInt,
        column: UInt
    )
}

@_spi(Internals)
public final class TestingSystem: Sendable {

    public static let shared = TestingSystem()

    public var isSwiftTestingRunning: Bool {
        (self as? SwiftTestingSystem)?.isRunning ?? false
    }

    public var isSwiftTestingCompletionAttached: Bool {
        (self as? SwiftTestingSystem)?.isTestCompletionAttached ?? false
    }

    var environment: TestingSystemEnvironment? {
        if let swiftTestingFramework = self as? SwiftTestingSystem {
            return swiftTestingFramework.environment
        } else {
            return nil
        }
    }

    public func record(
        message: String,
        fileID: StaticString,
        filePath: StaticString,
        line: UInt,
        column: UInt
    ) {
        if let swiftTestingSystem = self as? SwiftTestingSystem, swiftTestingSystem.isRunning {
            swiftTestingSystem.record(
                message: message,
                fileID: fileID,
                filePath: filePath,
                line: line,
                column: column
            )
        } else {
            XCTFail(message, file: filePath, line: line)
        }
    }
}
