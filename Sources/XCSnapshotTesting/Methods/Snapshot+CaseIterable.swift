extension SyncSnapshot where Input: CaseIterable & Sendable, Output == StringBytes, Input.AllCases: Sendable {
    /// A strategy for snapshot the output for every input of a function. The format of the
    /// snapshot is a comma-separated value (CSV) file that shows the mapping of inputs to outputs.
    ///
    /// - Parameter witness: A snapshot value on the output of the function to be snapshot.
    /// - Returns: A snapshot strategy on functions `(Value) -> A` that feeds every possible input
    ///   into the function and records the output into a CSV file.
    ///
    /// ```swift
    /// enum Direction: String, CaseIterable {
    ///   case up, down, left, right
    ///   var rotatedLeft: Direction {
    ///     switch self {
    ///     case .up:    return .left
    ///     case .down:  return .right
    ///     case .left:  return .down
    ///     case .right: return .up
    ///     }
    ///   }
    /// }
    ///
    /// try assert(
    ///   of: \Direction.rotatedLeft,
    ///   as: .func(into: .description)
    /// )
    /// ```
    ///
    /// Records:
    ///
    /// ```csv
    /// "up","left"
    /// "down","right"
    /// "left","down"
    /// "right","up"
    /// ```
    public static func `func`<A>(
        into witness: SyncSnapshot<A, Output>
    ) -> SyncSnapshot<@Sendable (Input) -> A, Output> {
        let snapshot = IdentitySyncSnapshot.lines.map { executor in
            executor.pullback { (f: @escaping @Sendable (Input) -> A, continuation) in
                Input.allCases.map { input in
                    Sync { (f: @escaping @Sendable (Input) -> A, continuation) in
                        witness.executor(f(input)) { result in
                            switch result {
                            case .success(let output):
                                continuation.resume(returning: (input, output))
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                }
                .sequence()
                .map {
                    $0
                    .map { "\"\($0)\",\"\($1)\"" }
                    .joined(separator: "\n")
                }
                .callAsFunction(f) {
                    continuation.resume(with: $0)
                }
            }
        }

        return .init(
            pathExtension: "csv",
            attachmentGenerator: snapshot.attachmentGenerator,
            executor: snapshot.executor
        )
    }
}
