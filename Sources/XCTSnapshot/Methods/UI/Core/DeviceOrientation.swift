import Foundation

public enum DeviceOrientation: Sendable {

  public static let landscape: Self = .landscape(.extended)
  public static let portrait: Self = .portrait(.extended)

  case landscape(DeviceLayoutRatio)
  case portrait(DeviceLayoutRatio)
}

public struct DeviceLayoutRatio: Sendable, RawRepresentable, ExpressibleByFloatLiteral, Hashable,
  Comparable
{

  public static let compact: Self = .init(rawValue: 1 / 3)
  public static let medium: Self = .init(rawValue: 0.5)
  public static let regular: Self = .init(rawValue: 2 / 3)
  public static let extended: Self = .init(rawValue: 1)

  public var description: String {
    switch self {
    case .compact: return "Compact"
    case .medium: return "Medium"
    case .regular: return "Regular"
    case .extended: return "Extended"
    default: return "Custom(\(rawValue))"
    }
  }

  public let rawValue: Double

  public init(rawValue: Double) {
    precondition(rawValue >= 0 && rawValue <= 1, "Raw value must be between 0 and 1")
    self.rawValue = rawValue
  }

  public init(floatLiteral value: Double) {
    self.init(rawValue: value)
  }

  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.rawValue < rhs.rawValue
  }

  public static func > (lhs: Self, rhs: Self) -> Bool {
    lhs.rawValue > rhs.rawValue
  }
}
