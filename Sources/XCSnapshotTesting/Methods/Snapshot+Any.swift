import Foundation

extension SyncSnapshot where Output == StringBytes {
    /// A snapshot strategy that captures a value's textual description from `String`'s
    /// `init(describing:)` initializer.
    ///
    /// ``` swift
    /// try assert(of: user, as: .description)
    /// ```
    ///
    /// Records:
    ///
    /// ```
    /// User(bio: "Blobbed around the world.", id: 1, name: "Blobby")
    /// ```
    public static var description: SyncSnapshot<Input, Output> {
        IdentitySyncSnapshot.lines.pullback {
            String(describing: $0)
        }
    }
}

extension SyncSnapshot where Output == StringBytes {
    /// A snapshot strategy for comparing any structure based on their JSON representation.
    ///
    /// This strategy serializes the input value into a JSON-formatted string using
    /// `JSONSerialization` with the following options:
    /// - `.prettyPrinted` for human-readable formatting
    /// - `.sortedKeys` to ensure consistent key ordering
    /// - `.fragmentsAllowed` for partial JSON outputs
    ///
    /// The result is a `StringBytes` snapshot containing the JSON-encoded data.
    ///
    /// - Available on: macOS 10.13+, watchOS 4.0+, tvOS 11.0+
    /// - Example: `assert(of: user, as: .json)`
    public static var json: SyncSnapshot<Input, Output> {
        let options: JSONSerialization.WritingOptions = [
            .prettyPrinted,
            .sortedKeys,
            .fragmentsAllowed,
        ]

        let snapshot = IdentitySyncSnapshot.lines.pullback { (data: Input) in
            try String(
                decoding: JSONSerialization.data(
                    withJSONObject: data,
                    options: options
                ),
                as: UTF8.self
            )
        }

        return .init(
            pathExtension: "json",
            attachmentGenerator: snapshot.attachmentGenerator,
            executor: snapshot.executor
        )
    }
}

private let snapshotDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(abbreviation: "UTC")
    return formatter
}()
