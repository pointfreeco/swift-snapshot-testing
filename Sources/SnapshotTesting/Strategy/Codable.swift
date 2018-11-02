import Foundation

extension Strategy where A: Encodable, B == String {
  @available(OSX 10.13, *)
  public static var json: Strategy {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return .json(encoder)
  }

  public static func json(_ encoder: JSONEncoder) -> Strategy {
    var strategy = SimpleStrategy<String>.lines.pullback { (encodable: A) in
      try! String(decoding: encoder.encode(encodable), as: UTF8.self)
    }
    strategy.pathExtension = "json"
    return strategy
  }

  #if !os(Linux)
  public static var plist: Strategy {
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .xml
    return .plist(encoder)
  }

  public static func plist(_ encoder: PropertyListEncoder) -> Strategy {
    var strategy = SimpleStrategy<String>.lines.pullback { (encodable: A) in
      try! String(decoding: encoder.encode(encodable), as: UTF8.self)
    }
    strategy.pathExtension = "plist"
    return strategy
  }
  #endif
}
