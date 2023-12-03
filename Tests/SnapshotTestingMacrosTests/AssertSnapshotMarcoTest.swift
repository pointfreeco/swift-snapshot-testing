import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(SnapshotTestingMacros)
import SnapshotMacros
import SnapshotTesting
import SnapshotTestingMacros
let testMacros: [String: Macro.Type] = [
    "AssertSnapshotEqual": AssertSnapshotEqualMacro.self,
]
#endif

final class SnapshotTestingMacroTests: XCTestCase {
    func testMacro() throws {
        #if canImport(SnapshotTestingMacros)
        let data = Data([0x54, 0x42, 0x44, 0x45])
        if let value = String(data: data, encoding: .utf8) {
            assertMacroExpansion(
            """
            #AssertSnapshotEqual(of: \(value), as: .lines)
            """,
            expandedSource: """
            assertSnapshot(of: TBDE, as: .lines)
            """,
            macros: testMacros
            )
        }
        else {
            XCTFail("Failed to convert data")
        }
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testData() {
        #if canImport(SnapshotTestingMacros)
        let data = Data([0x54, 0x42, 0x44, 0x45])
        if let value = String(data: data, encoding: .utf8) {
            #AssertSnapshotEqual(of: value, as: .lines)
        } else {
            XCTFail("Failed to convert data")
        }
        #endif
    }
}
