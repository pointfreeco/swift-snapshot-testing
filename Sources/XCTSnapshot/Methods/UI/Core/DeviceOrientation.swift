import Foundation

/// Represents the orientation of a device, either landscape or portrait.
///
/// - Note: This type is `Sendable` to allow safe sharing across concurrent operations.
public enum DeviceOrientation: Sendable {

    /// A landscape orientation with an extended layout ratio.
    public static let landscape: Self = .landscape(.extended)

    /// A portrait orientation with an extended layout ratio.
    public static let portrait: Self = .portrait(.extended)

    /// A device orientation in landscape mode, with a specific layout ratio.
    case landscape(DeviceLayoutRatio)

    /// A device orientation in portrait mode, with a specific layout ratio.
    case portrait(DeviceLayoutRatio)
}

/// Represents a device's layout ratio, with predefined values for compact, medium, regular, and extended.
/// The raw value is a Double between 0 and 1, representing the ratio.
/// - SeeAlso: DeviceOrientation
///
/// - Note: This type is `Sendable` to allow safe sharing across concurrent operations.
public struct DeviceLayoutRatio: Sendable, RawRepresentable, ExpressibleByFloatLiteral, Hashable, Comparable {

    /// A compact layout ratio (1/3).
    public static let compact: Self = .init(rawValue: 1 / 3)

    /// A medium layout ratio (0.5).
    public static let medium: Self = .init(rawValue: 0.5)

    /// A regular layout ratio (2/3).
    public static let regular: Self = .init(rawValue: 2 / 3)

    /// An extended layout ratio (1).
    public static let extended: Self = .init(rawValue: 1)

    /// The raw value representing the layout ratio, between 0 and 1.
    public let rawValue: Double

    /// Initializes a `DeviceLayoutRatio` with a given raw value.
    /// - Parameter rawValue: A Double between 0 and 1.
    public init(rawValue: Double) {
        precondition(rawValue >= 0 && rawValue <= 1, "Raw value must be between 0 and 1")
        self.rawValue = rawValue
    }

    /// Initializes a `DeviceLayoutRatio` with a float literal.
    /// - Parameter value: The float value to use as the raw value.
    public init(floatLiteral value: Double) {
        self.init(rawValue: value)
    }

    /// Compares two `DeviceLayoutRatio` instances.
    /// - Parameters:
    ///   - lhs: The left-hand side instance.
    ///   - rhs: The right-hand side instance.
    /// - Returns: `true` if lhs is less than rhs, otherwise `false`.
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Compares two `DeviceLayoutRatio` instances.
    /// - Parameters:
    ///   - lhs: The left-hand side instance.
    ///   - rhs: The right-hand side instance.
    /// - Returns: `true` if lhs is greater than rhs, otherwise `false`.
    public static func > (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue > rhs.rawValue
    }
}
