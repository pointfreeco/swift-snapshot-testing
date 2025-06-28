import Foundation

extension String {

    func indenting(by count: Int) -> String {
        self.indenting(with: String(repeating: " ", count: count))
    }

    func indenting(with prefix: String) -> String {
        guard !prefix.isEmpty else { return self }
        return self.replacingOccurrences(
            of: #"([^\n]+)"#,
            with: "\(prefix)$1",
            options: .regularExpression
        )
    }

    func hashCount(isMultiline: Bool) -> Int {
        let (quote, offset) = isMultiline ? ("\"\"\"", 2) : ("\"", 0)
        var substring = self[...]
        var hashCount = self.contains(#"\"#) ? 1 : 0
        let pattern = "(\(quote)[#]*)"
        while let range = substring.range(of: pattern, options: .regularExpression) {
            let count = substring.distance(from: range.lowerBound, to: range.upperBound) - offset
            hashCount = max(count, hashCount)
            substring = substring[range.upperBound...]
        }
        return hashCount
    }
}
