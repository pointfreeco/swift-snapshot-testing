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
  
  /// A snapshot strategy for comparing requests based on a cURL representation.
  public static let curl = SimplySnapshotting.lines.pullback { (request: URLRequest) in

    var components = ["curl"]

    // HTTP Method
    let httpMethod = request.httpMethod!
    switch httpMethod {
    case "GET": break
    case "HEAD": components.append("--head")
    default: components.append("--request \(httpMethod)")
    }

    // Headers
    if let headers = request.allHTTPHeaderFields {
      for (field, value) in headers where field != "Cookie" {
        let escapedValue = value.replacingOccurrences(of: "\"", with: "\\\"")
        components.append("--header \"\(field): \(escapedValue)\"")
      }
    }

    // Body
    if let httpBodyData = request.httpBody, let httpBody = String(data: httpBodyData, encoding: .utf8) {
      var escapedBody = httpBody.replacingOccurrences(of: "\\\"", with: "\\\\\"")
      escapedBody = escapedBody.replacingOccurrences(of: "\"", with: "\\\"")
      
      components.append("--data '\(escapedBody)'")
    }
    
    // Cookies
    if let cookie = request.allHTTPHeaderFields?["Cookie"] {
      let escapedValue = cookie.replacingOccurrences(of: "\"", with: "\\\"")
      components.append("--cookie \"\(escapedValue)\"")
    }

    // URL
    components.append("\"\(request.url!.absoluteString)\"")

    return components.joined(separator: " \\\n\t")
  }
}
