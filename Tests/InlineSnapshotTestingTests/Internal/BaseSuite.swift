import Testing
import SnapshotTesting

@Suite(.snapshots(record: .failed, diffTool: .ksdiff))
struct BaseSuite {
}
