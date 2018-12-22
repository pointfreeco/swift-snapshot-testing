import Foundation

extension Snapshotting where Value == URLRequest, Format == String {
  /// A snapshot strategy for comparing requests based on raw equality.
  public static let raw = SimplySnapshotting.lines.pullback { (request: URLRequest) in
    let method = "\(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "(null)")"

    let headers = (request.allHTTPHeaderFields ?? [:])
      .map { key, value in "\(key): \(value)" }
      .sorted()

    let body: [String]
    do {
      if #available(iOS 11.0, macOS 10.13, tvOS 11.0, *) {
      body = try request.httpBody
        .map { try JSONSerialization.jsonObject(with: $0, options: []) }
        .map { try JSONSerialization.data(withJSONObject: $0, options: [.prettyPrinted, .sortedKeys]) }
        .map { ["\n\(String(decoding: $0, as: UTF8.self))"] }
        ?? []
      } else {
        throw NSError.init(domain: "", code: 1, userInfo: nil)
      }
    }
    catch {
      body = request.httpBody
        .map { ["\n\(String(decoding: $0, as: UTF8.self))"] }
        ?? []
    }

    return ([method] + headers + body).joined(separator: "\n")
  }
}
