import Foundation

extension URLRequest: Snapshot {
  public var snapshotFormat: String {
    let lines = ["\(self.httpMethod!) \(self.url!)"]
      + (self.allHTTPHeaderFields ?? [:]).map { "\($0): \($1)" }

    let lines2 = lines
      + (self.httpBody.map { [String(data: $0, encoding: .utf8)!] } ?? [])

    return lines2.joined(separator: "\n")
  }
}
