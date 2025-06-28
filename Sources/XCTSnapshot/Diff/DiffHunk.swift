import Foundation

// MARK: - Formatted Change Representation
/// Represents a group of changes (hunk) in patch format.
struct DiffHunk {
    /// Start index in the first collection.
    let firstStart: Int

    /// Number of lines in the first collection.
    let firstLength: Int

    /// Start index in the second collection.
    let secondStart: Int

    /// Number of lines in the second collection.
    let secondLength: Int

    /// Formatted lines with change indicators.
    let lines: [String]

    /// Generates the hunk header in patch format.
    var patchMarker: String {
        let firstMarker = "−\(firstStart + 1),\(firstLength)"
        let secondMarker = "+\(secondStart + 1),\(secondLength)"
        return "@@ \(firstMarker) \(secondMarker) @@"
    }

    /// Combines two hunks into one.
    static func + (lhs: DiffHunk, rhs: DiffHunk) -> DiffHunk {
        DiffHunk(
            firstStart: lhs.firstStart,
            firstLength: lhs.firstLength + rhs.firstLength,
            secondStart: lhs.secondStart,
            secondLength: lhs.secondLength + rhs.secondLength,
            lines: lhs.lines + rhs.lines
        )
    }

    /// Default initializer with default values.
    init(
        firstStart: Int = 0,
        firstLength: Int = 0,
        secondStart: Int = 0,
        secondLength: Int = 0,
        lines: [String] = []
    ) {
        self.firstStart = firstStart
        self.firstLength = firstLength
        self.secondStart = secondStart
        self.secondLength = secondLength
        self.lines = lines
    }
}
