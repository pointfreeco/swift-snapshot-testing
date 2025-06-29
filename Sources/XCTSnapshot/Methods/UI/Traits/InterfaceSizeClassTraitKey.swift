#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
#elseif os(macOS)
@preconcurrency import AppKit
#endif

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
/// A size class that describes the horizontal or vertical space available for a user interface.
///
/// `InterfaceSizeClass` helps determine how UI elements should layout based on the available space.
/// Commonly used to differentiate between compact and regular layouts for different device sizes and orientations.
public enum InterfaceSizeClass: Sendable, Hashable {
    /// The size class is not specified.
    case unspecified
    /// The size class is regular (typically for larger screens or orientations).
    case regular
    /// The size class is compact (typically for smaller screens or orientations).
    case compact
}

/// A structure representing the horizontal and vertical interface size classes for a device.
///
/// `DeviceInterfaceSizeClass` combines horizontal and vertical size classes to fully describe the layout environment of a device.
/// This helps in creating adaptive UIs that respond appropriately to different screen sizes and orientations.
public struct DeviceInterfaceSizeClass: Sendable, Hashable {

    /// The horizontal interface size class.
    public let horizontal: InterfaceSizeClass

    /// The vertical interface size class.
    public let vertical: InterfaceSizeClass

    /// Initializes a `DeviceInterfaceSizeClass` with the specified horizontal and vertical size classes.
    ///
    /// - Parameters:
    ///   - horizontal: The horizontal interface size class.
    ///   - vertical: The vertical interface size class.
    public init(horizontal: InterfaceSizeClass, vertical: InterfaceSizeClass) {
        self.horizontal = horizontal
        self.vertical = vertical
    }
}

/// A struct that dynamically determines the device interface size class based on a given size.
///
/// `DeviceDynamicInterfaceSizeClass` allows you to define how interface size classes should be determined
/// for different device sizes. This is useful for adaptive UI layouts that need to respond to different
/// screen sizes and orientations.
///
/// You can create a dynamic size class provider using either a closure or a constant value.
///
/// Example usage with a closure:
/// ```swift
/// let dynamicSizeClass = DeviceDynamicInterfaceSizeClass { size in
///     if size.width < 768 {
///         return .compact
///     } else {
///         return .regular
///     }
/// }
/// let sizeClass = dynamicSizeClass(CGSize(width: 500, height: 300)) // Returns .compact
/// ```
///
/// Example usage with a constant:
/// ```swift
/// let constantSizeClass = DeviceDynamicInterfaceSizeClass(constant: .regular)
/// let sizeClass = constantSizeClass(CGSize(width: 1000, height: 800)) // Returns .regular
/// ```
public struct DeviceDynamicInterfaceSizeClass: Sendable {

    private let provider: @Sendable (CGSize) -> DeviceInterfaceSizeClass

    /// Creates a `DeviceDynamicInterfaceSizeClass` instance using a provider closure.
    ///
    /// - Parameter provider: A closure that takes a size and returns the corresponding interface size class.
    public init(provider: @escaping @Sendable (CGSize) -> DeviceInterfaceSizeClass) {
        self.provider = provider
    }

    /// Creates a `DeviceDynamicInterfaceSizeClass` instance with a constant value.
    ///
    /// - Parameter constant: The interface size class to always return.
    public init(constant: DeviceInterfaceSizeClass) {
        self.init(provider: { _ in constant })
    }

    /// Evaluates the interface size class for the given size.
    ///
    /// - Parameter size: The size to evaluate.
    /// - Returns: The interface size class corresponding to the provided size.
    public func callAsFunction(_ size: CGSize) -> DeviceInterfaceSizeClass {
        provider(size)
    }
}

// MARK: - iPhone
extension DeviceDynamicInterfaceSizeClass {

    // MARK: - iPhone 16

    public static let iPhone16ProMax = withRegularLandscape

    public static let iPhone16Pro = withCompactLandscape

    public static let iPhone16Plus = withRegularLandscape

    public static let iPhone16 = withCompactLandscape

    public static let iPhone16e = withCompactLandscape

    // MARK: - iPhone 15

    public static let iPhone15ProMax = withRegularLandscape

    public static let iPhone15Pro = withCompactLandscape

    public static let iPhone15Plus = withRegularLandscape

    public static let iPhone15 = withCompactLandscape

    // MARK: - iPhone 14

    public static let iPhone14ProMax = withRegularLandscape

    public static let iPhone14Pro = withCompactLandscape

    public static let iPhone14Plus = withRegularLandscape

    public static let iPhone14 = withCompactLandscape

    // MARK: - iPhone 13

    public static let iPhone13ProMax = withRegularLandscape

    public static let iPhone13Pro = withCompactLandscape

    public static let iPhone13 = withCompactLandscape

    public static let iPhone13Mini = withCompactLandscape

    // MARK: - iPhone 12

    public static let iPhone12ProMax = withRegularLandscape

    public static let iPhone12Pro = withCompactLandscape

    public static let iPhone12 = withCompactLandscape

    public static let iPhone12Mini = withCompactLandscape

    // MARK: - iPhone 11

    public static let iPhone11ProMax = withRegularLandscape

    public static let iPhone11Pro = withCompactLandscape

    public static let iPhone11 = withRegularLandscape

    // MARK: - iPhone XS

    public static let iPhoneXSMax = withRegularLandscape

    public static let iPhoneXS = withCompactLandscape

    // MARK: - iPhone XR

    public static let iPhoneXR = withRegularLandscape

    // MARK: - iPhone X

    public static let iPhoneX = withCompactLandscape

    // MARK: - iPhone 8

    public static let iPhone8Plus = withRegularLandscape

    public static let iPhone8 = withCompactLandscape

    // MARK: - iPhone SE

    public static let iPhoneSE = withCompactLandscape

    // MARK: - iPhone Private Methods

    private static let withRegularLandscape = iOS(
        landscape: .init(horizontal: .regular, vertical: .compact)
    )

    private static let withCompactLandscape = iOS(
        landscape: .init(horizontal: .compact, vertical: .compact)
    )

    private static func iOS(
        landscape: @autoclosure @escaping @Sendable () -> DeviceInterfaceSizeClass
    ) -> DeviceDynamicInterfaceSizeClass {
        DeviceDynamicInterfaceSizeClass {
            if $0.width > $0.height {
                return landscape()
            }

            return .init(
                horizontal: .compact,
                vertical: .regular
            )
        }
    }
}

// MARK: - iPads
extension DeviceDynamicInterfaceSizeClass {

    public static let iPadOS = DeviceDynamicInterfaceSizeClass { size in
        let horizontal: InterfaceSizeClass
        let vertical: InterfaceSizeClass

        if size.width >= size.height * 0.75 {
            horizontal = .regular
        } else {
            horizontal = .compact
        }

        if size.height > size.width * 0.5 {
            vertical = .regular
        } else {
            vertical = .compact
        }

        return .init(horizontal: horizontal, vertical: vertical)
    }
}

// MARK: - Regular Sizes
extension DeviceDynamicInterfaceSizeClass {

    public static let macOS = DeviceDynamicInterfaceSizeClass(
        constant: DeviceInterfaceSizeClass(horizontal: .regular, vertical: .regular)
    )

    public static let tvOS = DeviceDynamicInterfaceSizeClass(
        constant: DeviceInterfaceSizeClass(horizontal: .regular, vertical: .regular)
    )

    public static let visionOS = DeviceDynamicInterfaceSizeClass(
        constant: DeviceInterfaceSizeClass(horizontal: .regular, vertical: .regular)
    )
}

// MARK: - WatchOS
extension DeviceDynamicInterfaceSizeClass {

    public static let watchOS = DeviceDynamicInterfaceSizeClass(
        constant: DeviceInterfaceSizeClass(horizontal: .compact, vertical: .compact)
    )
}

#if os(iOS) || os(tvOS) || os(visionOS)
private struct DeviceInterfaceSizeClassTraitKey: TraitKey {

    static let defaultValue = DeviceInterfaceSizeClass(
        horizontal: .unspecified,
        vertical: .unspecified
    )

    @available(iOS 17, tvOS 17, *)
    static func apply(_ value: Value, to traitsOverrides: inout UITraitOverrides) {
        traitsOverrides.verticalSizeClass = .init(value.vertical)
        traitsOverrides.horizontalSizeClass = .init(value.horizontal)
    }

    static func apply(_ value: Value, to traitCollection: inout UITraitCollection) {
        #if os(visionOS)
        traitCollection = traitCollection.modifyingTraits {
            $0.verticalSizeClass = .init(value.vertical)
            $0.horizontalSizeClass = .init(value.horizontal)
        }
        #else
        if #available(iOS 17, tvOS 17, *) {
            traitCollection = traitCollection.modifyingTraits {
                $0.verticalSizeClass = .init(value.vertical)
                $0.horizontalSizeClass = .init(value.horizontal)
            }
        } else {
            traitCollection = .init(traitsFrom: [
                .init(verticalSizeClass: .init(value.vertical)),
                .init(horizontalSizeClass: .init(value.horizontal)),
            ])
        }
        #endif
    }
}

extension UIUserInterfaceSizeClass {

    fileprivate init(_ interfaceSizeClass: InterfaceSizeClass) {
        switch interfaceSizeClass {
        case .unspecified:
            self = .unspecified
        case .regular:
            self = .regular
        case .compact:
            self = .compact
        }
    }
}

extension Traits {

    /// Specifies the size class for the device interface.
    public var deviceInterfaceSizeClass: DeviceInterfaceSizeClass {
        get { self[DeviceInterfaceSizeClassTraitKey.self] }
        set { self[DeviceInterfaceSizeClassTraitKey.self] = newValue }
    }

    /// Creates a `Traits` instance with the specified device interface size class.
    public init(deviceInterfaceSizeClass: DeviceInterfaceSizeClass) {
        self.init()
        self.deviceInterfaceSizeClass = deviceInterfaceSizeClass
    }
}
#endif
#endif
