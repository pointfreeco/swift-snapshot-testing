#if canImport(Testing)
import Testing
import SnapshotTesting

@Suite(.record(.failed), .diffTool(.ksdiff), .finalizeSnapshots)
struct BaseSuite {}
#endif
