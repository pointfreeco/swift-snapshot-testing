import Foundation

@_spi(Internals)
public struct SnapshotFailure: Sendable {

    public let message: String
    public let reason: SnapshotFailContext.Reason

    init(
        message: String,
        context: SnapshotFailContext
    ) {
        self.message = message
        self.reason = context.reason
    }
}
