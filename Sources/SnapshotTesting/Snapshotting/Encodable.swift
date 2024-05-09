import Foundation

extension Snapshotting where Value: Encodable, Format == String {
  /// A snapshot strategy for comparing encodable structures based on their JSON representation.
  ///
  /// ```swift
  /// assertSnapshot(of: user, as: .json)
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
  @available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, visionOS 1.0, *)
  public static var json: Snapshotting {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return .json(encoder)
  }

  /// A snapshot strategy for comparing encodable structures based on their JSON representation.
  ///
  /// - Parameter encoder: A JSON encoder.
  public static func json(_ encoder: JSONEncoder) -> Snapshotting {
    var snapshotting = SimplySnapshotting.lines.pullback { (encodable: Value) in
      try! String(decoding: encoder.encode(encodable), as: UTF8.self)
    }
    snapshotting.pathExtension = "json"
    return snapshotting
  }

  /// A snapshot strategy for comparing encodable structures based on their property list
  /// representation.
  ///
  /// ```swift
  /// assertSnapshot(of: user, as: .plist)
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
  public static var plist: Snapshotting {
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .xml
    return .plist(encoder)
  }

  /// A snapshot strategy for comparing encodable structures based on their property list
  /// representation.
  ///
  /// - Parameter encoder: A property list encoder.
  public static func plist(_ encoder: PropertyListEncoder) -> Snapshotting {
    var snapshotting = SimplySnapshotting.lines.pullback { (encodable: Value) in
      try! String(decoding: encoder.encode(encodable), as: UTF8.self)
    }
    snapshotting.pathExtension = "plist"
    return snapshotting
  }
}
