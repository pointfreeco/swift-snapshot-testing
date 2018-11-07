import Foundation

extension Strategy where Snapshottable: Encodable, Format == String {
  @available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
  public static var json: Strategy {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return .json(encoder)
  }

  public static func json(_ encoder: JSONEncoder) -> Strategy {
    var strategy = SimpleStrategy.lines.pullback { (encodable: Snapshottable) in
      try! String(decoding: encoder.encode(encodable), as: UTF8.self)
    }
    strategy.pathExtension = "json"
    return strategy
  }

  public static var plist: Strategy {
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .xml
    return .plist(encoder)
  }

  public static func plist(_ encoder: PropertyListEncoder) -> Strategy {
    var strategy = SimpleStrategy.lines.pullback { (encodable: Snapshottable) in
      try! String(decoding: encoder.encode(encodable), as: UTF8.self)
    }
    strategy.pathExtension = "plist"
    return strategy
  }
}
