import Foundation

// MARK: - Difference Structure
/// Represents a difference between two collections of elements.
struct Difference<Element> {
    /// Origin of elements in the comparison
    enum Origin {
        case first  // Element unique to the first collection
        case second  // Element unique to the second collection
        case common  // Element present in both collections
    }

    /// Elements involved in the difference
    let elements: [Element]
    /// Origin of elements (first collection, second collection, or common)
    let origin: Origin
}

extension Array where Element: Hashable {

    // MARK: - Main Comparison Function
    /// Calculates differences between collections using the Longest Common Subsequence (LCS) algorithm.
    /// - Parameters:
    ///   - first: First collection to compare
    ///   - second: Second collection to compare
    /// - Returns: List of identified differences
    func diffing(_ other: [Element]) -> [Difference<Element>] {
        // 1. Maps element indices from first collection
        var elementIndices = [Element: [Int]]()
        for (index, element) in enumerated() {
            elementIndices[element, default: []].append(index)
        }

        // 2. Finds Longest Common Subsequence (LCS)
        var longestSubsequence = (
            overlap: [Int: Int](),  // Overlap table
            firstIndex: 0,  // Start index in first collection
            secondIndex: 0,  // Start index in second collection
            length: 0  // Subsequence length
        )

        // Iterates through second collection to find matches
        for pair in other.enumerated() {
            guard let indices = elementIndices[pair.element] else { continue }

            for firstIndex in indices {
                let currentLength = (longestSubsequence.overlap[firstIndex - 1] ?? 0) + 1
                var newOverlap = longestSubsequence.overlap
                newOverlap[firstIndex] = currentLength

                // Updates longest subsequence found
                if currentLength > longestSubsequence.length {
                    longestSubsequence.overlap = newOverlap
                    longestSubsequence.firstIndex = firstIndex - currentLength + 1
                    longestSubsequence.secondIndex = pair.offset - currentLength + 1
                    longestSubsequence.length = currentLength
                }
            }
        }

        // 3. No common subsequence case
        guard longestSubsequence.length > 0 else {
            return [
                Difference(elements: self, origin: .first),
                Difference(elements: other, origin: .second),
            ].filter { !$0.elements.isEmpty }
        }

        // 4. Splits collections into parts for recursive analysis
        let (firstPart, secondPart) = (
            Array(self.prefix(upTo: longestSubsequence.firstIndex)),
            Array(other.prefix(upTo: longestSubsequence.secondIndex))
        )

        let (firstRemainder, secondRemainder) = (
            Array(self.suffix(from: longestSubsequence.firstIndex + longestSubsequence.length)),
            Array(other.suffix(from: longestSubsequence.secondIndex + longestSubsequence.length))
        )

        // 5. Combines results from analyzed parts recursively
        return firstPart.diffing(secondPart)
            + [
                Difference(
                    elements: Array(
                        self[
                            longestSubsequence.firstIndex..<longestSubsequence.firstIndex
                                + longestSubsequence.length
                        ]
                    ),
                    origin: .common
                )
            ]
            + firstRemainder.diffing(secondRemainder)
    }
}

extension [Difference<String>] {

    func groupping(context: Int = 4) -> [DiffHunk] {
        let figureSpace = "\u{2007}"  // Figure space (for alignment)

        // Processes each difference and groups into hunks
        let (finalHunk, hunks) = reduce(into: (current: DiffHunk(), hunks: [DiffHunk]())) {
            state,
            diff in

            let count = diff.elements.count

            switch diff.origin {
            // Case: Common elements with large context
            case .common where count > context * 2:
                let prefixLines = diff.elements.prefix(context).map(addPrefix(figureSpace))
                let suffixLines = diff.elements.suffix(context).map(addPrefix(figureSpace))

                let newHunk =
                    state.current
                    + DiffHunk(
                        firstLength: context,
                        secondLength: context,
                        lines: prefixLines
                    )

                state.current = DiffHunk(
                    firstStart: state.current.firstStart + state.current.firstLength + count - context,
                    firstLength: context,
                    secondStart: state.current.secondStart + state.current.secondLength + count - context,
                    secondLength: context,
                    lines: suffixLines
                )

                // Adds previous hunk if it contains changes
                if newHunk.lines.contains(where: { $0.hasPrefix("−") || $0.hasPrefix("+") }) {
                    state.hunks.append(newHunk)
                }

            // Case: Common elements with empty hunk
            case .common where state.current.lines.isEmpty:
                let suffixLines = diff.elements.suffix(context).map(addPrefix(figureSpace))
                state.current =
                    state.current
                    + DiffHunk(
                        firstStart: count - suffixLines.count,
                        firstLength: suffixLines.count,
                        secondStart: count - suffixLines.count,
                        secondLength: suffixLines.count,
                        lines: suffixLines
                    )

            // Case: Normal common elements
            case .common:
                let lines = diff.elements.map(addPrefix(figureSpace))
                state.current =
                    state.current
                    + DiffHunk(
                        firstLength: count,
                        secondLength: count,
                        lines: lines
                    )

            // Case: Removals (first collection elements)
            case .first:
                state.current =
                    state.current
                    + DiffHunk(
                        firstLength: count,
                        lines: diff.elements.map(addPrefix("−"))
                    )

            // Case: Additions (second collection elements)
            case .second:
                state.current =
                    state.current
                    + DiffHunk(
                        secondLength: count,
                        lines: diff.elements.map(addPrefix("+"))
                    )
            }
        }

        // Returns accumulated hunks + final hunk (if valid)
        return finalHunk.lines.isEmpty ? hunks : hunks + [finalHunk]
    }
}

// MARK: - Contextual Change Grouping
/// Helper function to add line prefixes
private func addPrefix(_ prefix: String) -> (String) -> String {
    { "\(prefix)\($0)\($0.hasSuffix(" ") ? "¬" : "")" }
}
