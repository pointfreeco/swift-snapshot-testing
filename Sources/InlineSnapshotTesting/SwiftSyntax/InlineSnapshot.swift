#if canImport(SwiftSyntax601)
import SwiftSyntax
import Foundation

public struct InlineSnapshot: Sendable, Hashable {

    public let reference: Data?
    public let diffable: Data
    public let wasRecording: Bool
    public let closureDescriptor: SnapshotClosureDescriptor
    public let function: String
    public let line: UInt
    public let column: UInt

    public init(
        reference: Data?,
        diffable: Data,
        wasRecording: Bool,
        closureDescriptor: SnapshotClosureDescriptor,
        function: String,
        line: UInt,
        column: UInt
    ) {
        self.reference = reference
        self.diffable = diffable
        self.wasRecording = wasRecording
        self.closureDescriptor = closureDescriptor
        self.function = function
        self.line = line
        self.column = column
    }
}
#endif
