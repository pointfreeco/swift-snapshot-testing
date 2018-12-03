import Foundation

extension Snapshotting where Value == URLRequest, Format == String {
  /// A snapshot strategy for comparing requests based on raw equality.
  public static let raw = SimplySnapshotting.lines.pullback { (request: URLRequest) in

    let method = "\(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "(null)")"

    let headers = (request.allHTTPHeaderFields ?? [:])
      .map { key, value in "\(key): \(value)" }
      .sorted()

    let body = request.httpBody
      .map { ["\n\(String(decoding: $0, as: UTF8.self))"] }
      ?? []

    return ([method] + headers + body).joined(separator: "\n")
  }
}
