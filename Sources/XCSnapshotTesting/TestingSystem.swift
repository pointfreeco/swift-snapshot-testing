import Foundation

#if canImport(XCTest)
@preconcurrency import XCTest
#endif

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

    func add(
        _ name: String,
        attachments: [SnapshotAttachment],
        fileID: StaticString,
        filePath: StaticString,
        line: UInt,
        column: UInt
    )

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

    public func add(
        _ name: String,
        attachments: [SnapshotAttachment],
        fileID: StaticString,
        filePath: StaticString,
        line: UInt,
        column: UInt
    ) {
        if let swiftTestingSystem = self as? SwiftTestingSystem, swiftTestingSystem.isRunning {
            swiftTestingSystem.add(
                name,
                attachments: attachments,
                fileID: fileID,
                filePath: filePath,
                line: line,
                column: column
            )
        } else {
            #if canImport(XCTest) && (os(iOS) || os(tvOS) || os(macOS) || os(visionOS) || os(watchOS))
            performOnMainThread {
                XCTContext.runActivity(named: name) { activity in
                    for attachment in attachments {
                        activity.add(
                            XCTAttachment(
                                uniformTypeIdentifier: attachment.uniformTypeIdentifier,
                                name: attachment.name,
                                payload: attachment.payload
                            )
                        )
                    }
                }
            }
            #endif
        }
    }

    public func record(
        message: String,
        fileID: StaticString,
        filePath: StaticString,
        line: UInt,
        column: UInt
    ) throws {
        if let swiftTestingSystem = self as? SwiftTestingSystem, swiftTestingSystem.isRunning {
            swiftTestingSystem.record(
                message: message,
                fileID: fileID,
                filePath: filePath,
                line: line,
                column: column
            )
        } else {
            #if canImport(XCTest)
            XCTFail(message, file: filePath, line: line)
            #else
            throw TestingFailure(
                message: message,
                fileID: fileID,
                filePath: filePath,
                line: line,
                column: column
            )
            #endif
        }
    }
}

#if !canImport(XCTest)
public struct TestingFailure: Error {
    public let message: String
    public let fileID: StaticString
    public let filePath: StaticString
    public let line: UInt
    public let column: UInt
}
#endif
