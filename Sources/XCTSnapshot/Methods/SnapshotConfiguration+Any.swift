import Foundation

extension SyncSnapshot where Output == StringBytes {
  /// A snapshot strategy that captures a value's textual description from `String`'s
  /// `init(describing:)` initializer.
  ///
  /// ``` swift
  /// assert(of: user, as: .description)
  /// ```
  ///
  /// Records:
  ///
  /// ```
  /// User(bio: "Blobbed around the world.", id: 1, name: "Blobby")
  /// ```
  public static var description: SyncSnapshot<Input, Output> {
    return IdentitySyncSnapshot.lines.pullback {
      StringBytes(rawValue: String(describing: $0))
    }
  }
}

@available(macOS 10.13, watchOS 4.0, tvOS 11.0, *)
extension SyncSnapshot where Output == StringBytes {
  /// A snapshot strategy for comparing any structure based on their JSON representation.
  public static var json: SyncSnapshot<Input, Output> {
    let options: JSONSerialization.WritingOptions = [
      .prettyPrinted,
      .sortedKeys,
      .fragmentsAllowed
    ]

    let snapshot = IdentitySyncSnapshot.lines.pullback { (data: Input) in
      try StringBytes(
        rawValue: String(
          decoding: JSONSerialization.data(
            withJSONObject: data,
            options: options
          ),
          as: UTF8.self
        )
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
