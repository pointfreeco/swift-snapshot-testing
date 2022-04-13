import Foundation

extension Snapshotting where Format == String {
  /// A snapshot strategy for comparing any structure based on a sanitized text dump.
  public static var dump: Snapshotting {
    return SimplySnapshotting.lines.pullback { snap($0) }
  }

  /// A snapshot strategy for comparing any structure based on a sanitized text dump.
  /// - Parameter renderChildren: whether to render all children for all types conforming to `AnySnapshotStringConvertible`
  public static func dump(renderChildren: Bool) -> Snapshotting {
    SimplySnapshotting.lines.pullback { snap($0, renderChildren: renderChildren) }
  }
}

@available(macOS 10.13, *)
extension Snapshotting where Format == String {
  /// A snapshot strategy for comparing any structure based on their JSON representation.
  public static var json: Snapshotting {
    let options: JSONSerialization.WritingOptions = [
      .prettyPrinted,
      .sortedKeys
    ]

    var snapshotting = SimplySnapshotting.lines.pullback { (data: Value) in
      try! String(decoding: JSONSerialization.data(withJSONObject: data,
                                                   options: options), as: UTF8.self)
    }
    snapshotting.pathExtension = "json"
    return snapshotting
  }
}

private func snap<T>(_ value: T, name: String? = nil, indent: Int = 0, renderChildren: Bool = false) -> String {
  let indentation = String(repeating: " ", count: indent)
  let mirror = Mirror(reflecting: value)
  var children: Mirror.Children = value is AnySnapshotStringConvertibleIgnoreChildNodes ? Mirror.Children([]) : mirror.children
  let count = children.count
  let bullet = count == 0 ? "-" : "▿"

  if let includedNodesProvider = value as? AnySnapshotStringConvertibleIncludedNodesProvider {
    let filtered = children.filter { child in
      guard let label = child.label, let includedNodes = type(of: includedNodesProvider).includedNodes else { return true }

      return includedNodes.contains(label)
    }

    children = Mirror.Children(filtered)
  }

  if let excludedNodesProvider = value as? AnySnapshotStringConvertibleExcludedNodesProvider {
    let excludedNodes = type(of: excludedNodesProvider).excludedNodes

    let filtered = children.filter { child in
      guard let label = child.label else { return true }

      return !excludedNodes.contains(label)
    }

    children = Mirror.Children(filtered)
  }

  let description: String
  switch (value, mirror.displayStyle) {
  case (_, .collection?):
    description = count == 1 ? "1 element" : "\(count) elements"
  case (_, .dictionary?):
    description = count == 1 ? "1 key/value pair" : "\(count) key/value pairs"
    children = sort(children)
  case (_, .set?):
    description = count == 1 ? "1 member" : "\(count) members"
    children = sort(children)
  case (_, .tuple?):
    description = count == 1 ? "(1 element)" : "(\(count) elements)"
  case (_, .optional?):
    let subjectType = String(describing: mirror.subjectType)
      .replacingOccurrences(of: " #\\d+", with: "", options: .regularExpression)
    description = count == 0 ? "\(subjectType).none" : "\(subjectType)"
  case (let value as AnySnapshotStringConvertible, _) where (renderChildren || value is AnySnapshotStringConvertibleDumpChildNodes):
    description = value.snapshotDescription
  case (let value as AnySnapshotStringConvertible, _):
    return "\(indentation)- \(name.map { "\($0): " } ?? "")\(value.snapshotDescription)\n"
  case (let value as CustomStringConvertible, _):
    description = value.description
  case (_, .class?), (_, .struct?):
    description = String(describing: mirror.subjectType)
      .replacingOccurrences(of: " #\\d+", with: "", options: .regularExpression)
    children = sort(children)
  case (_, .enum?):
    let subjectType = String(describing: mirror.subjectType)
      .replacingOccurrences(of: " #\\d+", with: "", options: .regularExpression)
    description = count == 0 ? "\(subjectType).\(value)" : "\(subjectType)"
  case (let value, _):
    description = String(describing: value)
  }

  let lines = ["\(indentation)\(bullet) \(name.map { "\($0): " } ?? "")\(description)\n"]
    + children.map { snap($1, name: $0, indent: indent + 2, renderChildren: renderChildren) }

  return lines.joined()
}

private func sort(_ children: Mirror.Children) -> Mirror.Children {
  return .init(
    children
      .map({ (child: $0, snap: snap($0)) })
      .sorted(by: { $0.snap < $1.snap })
      .map({ $0.child })
  )
}

/// A type with a customized snapshot dump representation.
///
/// Types that conform to the `AnySnapshotStringConvertible` protocol can provide their own representation to be used when converting an instance to a `dump`-based snapshot.
public protocol AnySnapshotStringConvertible {
  /// A textual snapshot dump representation of this instance.
  var snapshotDescription: String { get }
}

/// Implement thsi protocol to dump child nodes for the given type
public protocol AnySnapshotStringConvertibleDumpChildNodes {}
/// Implement this protocol to ignore dumping child nodes
public protocol AnySnapshotStringConvertibleIgnoreChildNodes {}

/// Properties to include child nodes
public protocol AnySnapshotStringConvertibleIncludedNodesProvider {
  /// Which nodes to include in the dump
  static var includedNodes: [String]? { get }
}

/// Properties to exclude child nodes
public protocol AnySnapshotStringConvertibleExcludedNodesProvider {
  /// Which nodes to exclude from the dump
  static var excludedNodes: [String] { get }
}

extension Character: AnySnapshotStringConvertible {
  public var snapshotDescription: String {
    return self.debugDescription
  }
}

extension Data: AnySnapshotStringConvertible {
  public var snapshotDescription: String {
    return self.debugDescription
  }
}

extension Date: AnySnapshotStringConvertible {
  public var snapshotDescription: String {
    return snapshotDateFormatter.string(from: self)
  }
}

extension NSObject: AnySnapshotStringConvertible {
  #if canImport(ObjectiveC)
  @objc open var snapshotDescription: String {
    return purgePointers(self.debugDescription)
  }
  #else
  open var snapshotDescription: String {
    return purgePointers(self.debugDescription)
  }
  #endif
}

extension String: AnySnapshotStringConvertible {
  public var snapshotDescription: String {
    return self.debugDescription
  }
}

extension Substring: AnySnapshotStringConvertible {
  public var snapshotDescription: String {
    return self.debugDescription
  }
}

extension URL: AnySnapshotStringConvertible {
  public var snapshotDescription: String {
    return self.debugDescription
  }
}

private let snapshotDateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
  formatter.calendar = Calendar(identifier: .gregorian)
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.timeZone = TimeZone(abbreviation: "UTC")
  return formatter
}()

func purgePointers(_ string: String) -> String {
  return string.replacingOccurrences(of: ":?\\s*0x[\\da-f]+(\\s*)", with: "$1", options: .regularExpression)
}
