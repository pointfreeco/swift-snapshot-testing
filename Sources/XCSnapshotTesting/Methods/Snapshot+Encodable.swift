import Foundation

extension SyncSnapshot where Input: Encodable & Sendable, Output == StringBytes {
    /// A snapshot strategy for comparing encodable structures based on their JSON representation.
    ///
    /// ```swift
    /// try assert(of: user, as: .json)
    /// ```
    ///
    /// Records:
    ///
    /// ```json
    /// {
    ///   "bio" : "Blobbed around the world.",
    ///   "id" : 1,
    ///   "name" : "Blobby"
    /// }
    /// ```
    public static var json: SyncSnapshot<Input, Output> {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return .json(encoder)
    }

    /// A snapshot strategy for comparing encodable structures based on their JSON representation.
    ///
    /// - Parameter encoder: A JSON encoder.
    public static func json(_ encoder: JSONEncoder) -> SyncSnapshot<Input, Output> {
        let snapshot = IdentitySyncSnapshot.lines.pullback { (encodable: Input) in
            try String(
                decoding: encoder.encode(encodable),
                as: UTF8.self
            )
        }

        return .init(
            pathExtension: "json",
            attachmentGenerator: snapshot.attachmentGenerator,
            executor: snapshot.executor
        )
    }

    /// A snapshot strategy for comparing encodable structures based on their property list
    /// representation.
    ///
    /// ```swift
    /// try assert(of: user, as: .plist)
    /// ```
    ///
    /// Records:
    ///
    /// ```xml
    /// <?xml version="1.0" encoding="UTF-8"?>
    /// <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    ///  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    /// <plist version="1.0">
    /// <dict>
    ///   <key>bio</key>
    ///   <string>Blobbed around the world.</string>
    ///   <key>id</key>
    ///   <integer>1</integer>
    ///   <key>name</key>
    ///   <string>Blobby</string>
    /// </dict>
    /// </plist>
    /// ```
    public static var plist: SyncSnapshot<Input, Output> {
        let encoder = Foundation.PropertyListEncoder()
        encoder.outputFormat = .xml
        return .plist(encoder)
    }

    /// A snapshot strategy for comparing encodable structures based on their property list
    /// representation.
    ///
    /// - Parameter encoder: A property list encoder.
    public static func plist(_ encoder: Foundation.PropertyListEncoder) -> SyncSnapshot<Input, Output> {
        let snapshot = IdentitySyncSnapshot.lines.pullback { (encodable: Input) in
            try String(
                decoding: encoder.encode(encodable),
                as: UTF8.self
            )
        }

        return .init(
            pathExtension: "plist",
            attachmentGenerator: snapshot.attachmentGenerator,
            executor: snapshot.executor
        )
    }
}
