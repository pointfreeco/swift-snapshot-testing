import Foundation

public protocol SnapshotStringConvertible {
  var snapshotDescription: String { get }
}

extension Date: SnapshotStringConvertible {
  public var snapshotDescription: String {
    return snapshotDateFormatter.string(from: self)
  }
}

extension NSObject: SnapshotStringConvertible {
  public var snapshotDescription: String {
    return self.debugDescription
      .replacingOccurrences(of: ": 0x[\\da-f]+", with: "", options: .regularExpression)
  }
}

private let snapshotDateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.timeZone = TimeZone(abbreviation: "UTC")
  return formatter
}()
