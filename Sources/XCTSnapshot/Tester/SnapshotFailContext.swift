import Foundation

@_spi(Internals)
public struct SnapshotFailContext: Sendable {

    public enum Reason: Sendable {
        case missing
        case doesNotMatch
        case allRecordMode
        case timeout
    }

    public let function: StaticString
    public let reason: Reason
    public let url: URL
    public let diff: String?
    public let additionalInformation: String?
    public let didWriteNewSnapshot: Bool

    init(
        function: StaticString,
        reason: Reason,
        url: URL,
        diff: String?,
        additionalInformation: String?,
        didWriteNewSnapshot: Bool
    ) {
        self.function = function
        self.reason = reason
        self.url = url
        self.diff = diff
        self.additionalInformation = additionalInformation
        self.didWriteNewSnapshot = didWriteNewSnapshot
    }
}
