#if canImport(Testing)
import Testing
import SnapshotTesting

@Suite(.record(.failed), .diffTool(.ksdiff), .platform(nil))
struct BaseSuite {
}
#endif
