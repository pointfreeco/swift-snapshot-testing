import Foundation

extension Strategy where A: Encodable {
  @available(OSX 10.13, *)
  public static var json: Strategy<A, String> {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return .json(encoder)
  }

  public static func json(_ encoder: JSONEncoder) -> Strategy<A, String> {
    return Strategy.lines.pullback { encodable in
      try! String(decoding: encoder.encode(encodable), as: UTF8.self)
    }
  }
}
