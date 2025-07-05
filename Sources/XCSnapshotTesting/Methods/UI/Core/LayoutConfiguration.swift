#if os(iOS) || os(tvOS) || os(visionOS) || os(watchOS)
import UIKit
#elseif os(macOS)
@preconcurrency import AppKit
#endif

#if os(iOS) || os(tvOS) || os(visionOS) || os(watchOS) || os(macOS)
/// Layout configuration for rendering elements in snapshot tests.
///
/// `LayoutConfiguration` defines properties like safe area margins, element size, and device traits
/// (e.g., orientation, screen size) to simulate different display scenarios.
///
/// This struct helps create consistent rendering conditions for snapshot tests by specifying layout properties
/// that mimic different devices and orientations. However, it's important to note that this configuration
/// only simulates visual conditions and does not actually execute tests on the specified platform. Due to
/// inherent differences in layout engines across platforms (iOS, macOS, tvOS), test results should be
/// validated on the target platform to account for framework-specific behaviors (UIKit, SwiftUI, AppKit).
///
/// - Note: This struct encapsulates screen size, safe area insets, and device-specific traits to enable
///   responsive UI layouts across iOS, iPadOS, and tvOS. It provides a way to standardize testing conditions
///   while acknowledging that final visual verification should occur on the actual target platform.
/// - SeeAlso: `LayoutConfiguration.iPadPro12_9`, `LayoutConfiguration.iPhone13`, `LayoutConfiguration.tv`
public struct LayoutConfiguration: Sendable {

    // MARK: - Internal static methods

    #if os(macOS)
    static func resolve(_ snapshotLayout: SnapshotLayout) -> LayoutConfiguration {
        switch snapshotLayout {
        case .sizeThatFits:
            return .init(safeArea: .init(), size: nil)
        case .fixed(let width, let height):
            let size = CGSize(width: width, height: height)
            return .init(safeArea: .init(), size: size)
        }
    }
    #elseif os(iOS) || os(tvOS) || os(visionOS)
    static func resolve(
        _ snapshotLayout: SnapshotLayout,
        with traits: Traits
    ) -> LayoutConfiguration {
        switch snapshotLayout {
        case .device(let deviceConfig):
            return .init(
                safeArea: deviceConfig.safeArea,
                size: deviceConfig.size,
                traits: deviceConfig.traits.merging(traits)
            )
        case .sizeThatFits:
            return .init(safeArea: .zero, size: nil, traits: traits)
        case .fixed(let width, let height):
            let size = CGSize(width: width, height: height)
            return .init(safeArea: .zero, size: size, traits: traits)
        }
    }
    #else
    static func resolve(_ snapshotLayout: SnapshotLayout) -> LayoutConfiguration {
        switch snapshotLayout {
        case .sizeThatFits:
            return .init(size: nil)
        case .fixed(let width, let height):
            let size = CGSize(width: width, height: height)
            return .init(size: size)
        }
    }
    #endif

    // MARK: - Public properties

    #if os(macOS)
    /// Margins for safe area layout (e.g., device notches or status bars).
    ///
    /// Default value: `.zero` (no additional margins).
    public let safeArea: NSEdgeInsets
    #elseif !os(watchOS)
    /// Margins for safe area layout (e.g., device notches or status bars).
    ///
    /// Default value: `.zero` (no additional margins).
    public let safeArea: UIEdgeInsets
    #endif

    /// Size of the element to render.
    ///
    /// When `nil`, the element uses its intrinsic content size.
    public let size: CGSize?

    #if os(iOS) || os(tvOS) || os(visionOS)
    /// Collection of UI traits like orientation, device size, and dark mode.
    ///
    /// Default value: `Traits()` (system default values).
    public let traits: Traits
    #endif

    // MARK: - Inits
    #if os(macOS)
    /// Initializes a `LayoutConfiguration` with the specified safe area and size.
    ///
    /// - Parameters:
    ///   - safeArea: The edge insets representing the safe area of the layout.
    ///   - size: The dimensions of the layout's viewing area.
    public init(
        safeArea: NSEdgeInsets = .init(),
        size: CGSize? = nil
    ) {
        self.safeArea = safeArea
        self.size = size
    }
    #elseif os(iOS) || os(tvOS) || os(visionOS)
    /// Initializes a layout configuration with default or custom values.
    ///
    /// - Parameters:
    ///   - safeArea: Margins for safe area (e.g., iPhone notch spacing).
    ///   - size: Desired element size (optional).
    ///   - traits: UI characteristics (e.g., portrait/landscape orientation).
    public init(
        safeArea: UIEdgeInsets = .zero,
        size: CGSize? = nil,
        traits: Traits = .init()
    ) {
        self.safeArea = safeArea
        self.size = size
        self.traits = traits
    }
    #else
    /// Initializes a layout configuration with default values.
    ///
    /// - Parameters:
    ///   - size: Desired element size (optional).
    public init(
        size: CGSize? = nil
    ) {
        self.size = size
    }
    #endif
}

#if os(iOS) || os(tvOS) || os(visionOS)

extension LayoutConfiguration {

    fileprivate struct EdgeInsets {

        static var zero: Self {
            .init(
                top: .zero,
                left: .zero,
                bottom: .zero,
                right: .zero
            )
        }

        let top: CGFloat?
        let left: CGFloat?
        let bottom: CGFloat?
        let right: CGFloat?

        init(
            top: CGFloat? = nil,
            left: CGFloat? = nil,
            bottom: CGFloat? = nil,
            right: CGFloat? = nil
        ) {
            self.top = top
            self.left = left
            self.bottom = bottom
            self.right = right
        }
    }
}

// MARK: - iPhone 16
extension LayoutConfiguration {

    public static let iPhone16ProMax: LayoutConfiguration = .iPhone16ProMax(.portrait)

    public static func iPhone16ProMax(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen6_9,
            portraitSafeArea: EdgeInsets(top: 62, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhone16ProMax
        )
    }

    public static let iPhone16Pro: LayoutConfiguration = .iPhone16Pro(.portrait)

    public static func iPhone16Pro(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen6_3,
            portraitSafeArea: EdgeInsets(top: 62, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhone16Pro
        )
    }

    public static let iPhone16Plus: LayoutConfiguration = .iPhone16Plus(.portrait)

    public static func iPhone16Plus(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen6_7v2,
            portraitSafeArea: EdgeInsets(top: 59, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhone16Plus
        )
    }

    public static let iPhone16: LayoutConfiguration = .iPhone16(.portrait)

    public static func iPhone16(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen6_1v2,
            portraitSafeArea: EdgeInsets(top: 59, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhone16
        )
    }
}

// MARK: - iPhone 15
extension LayoutConfiguration {

    public static let iPhone15ProMax: LayoutConfiguration = .iPhone15ProMax(.portrait)

    public static func iPhone15ProMax(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen6_7v2,
            portraitSafeArea: EdgeInsets(top: 59, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhone15ProMax
        )
    }

    public static let iPhone15Pro: LayoutConfiguration = .iPhone15Pro(.portrait)

    public static func iPhone15Pro(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen6_1v2,
            portraitSafeArea: EdgeInsets(top: 59, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhone15Pro
        )
    }

    public static let iPhone15Plus: LayoutConfiguration = .iPhone15Plus(.portrait)

    public static func iPhone15Plus(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen6_7v2,
            portraitSafeArea: EdgeInsets(top: 59, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhone15Plus
        )
    }

    public static let iPhone15: LayoutConfiguration = .iPhone15(.portrait)

    public static func iPhone15(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen6_1v2,
            portraitSafeArea: EdgeInsets(top: 59, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhone15
        )
    }
}

// MARK: - iPhone 14
extension LayoutConfiguration {

    public static let iPhone14ProMax: LayoutConfiguration = .iPhone14ProMax(.portrait)

    public static func iPhone14ProMax(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen6_7v2,
            portraitSafeArea: EdgeInsets(top: 59, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhone14ProMax
        )
    }

    public static let iPhone14Pro: LayoutConfiguration = .iPhone14Pro(.portrait)

    public static func iPhone14Pro(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen6_1v2,
            portraitSafeArea: EdgeInsets(top: 59, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhone14Pro
        )
    }

    public static let iPhone14Plus: LayoutConfiguration = .iPhone14Plus(.portrait)

    public static func iPhone14Plus(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen6_7v1,
            portraitSafeArea: EdgeInsets(top: 47, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhone14Plus
        )
    }

    public static let iPhone14: LayoutConfiguration = .iPhone14(.portrait)

    public static func iPhone14(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen6_1v1,
            portraitSafeArea: EdgeInsets(top: 47, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhone14
        )
    }
}

// MARK: - iPhone 13
extension LayoutConfiguration {

    public static let iPhone13ProMax: LayoutConfiguration = .iPhone13ProMax(.portrait)

    public static func iPhone13ProMax(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen6_7v1,
            portraitSafeArea: EdgeInsets(top: 47, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhone13ProMax
        )
    }

    public static let iPhone13Pro: LayoutConfiguration = .iPhone13Pro(.portrait)

    public static func iPhone13Pro(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen6_1v1,
            portraitSafeArea: EdgeInsets(top: 47, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhone13Pro
        )
    }

    public static let iPhone13: LayoutConfiguration = .iPhone13(.portrait)

    public static func iPhone13(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen6_1v1,
            portraitSafeArea: EdgeInsets(top: 47, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhone13
        )
    }

    public static let iPhone13Mini: LayoutConfiguration = .iPhone13Mini(.portrait)

    public static func iPhone13Mini(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen5_4,
            portraitSafeArea: EdgeInsets(top: 50, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhone13Mini
        )
    }
}

// MARK: - iPhone 12
extension LayoutConfiguration {

    public static let iPhone12ProMax: LayoutConfiguration = .iPhone12ProMax(.portrait)

    public static func iPhone12ProMax(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen6_7v1,
            portraitSafeArea: EdgeInsets(top: 50, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhone12ProMax
        )
    }

    public static let iPhone12Pro: LayoutConfiguration = .iPhone12Pro(.portrait)

    public static func iPhone12Pro(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen6_1v1,
            portraitSafeArea: EdgeInsets(top: 50, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhone12Pro
        )
    }

    public static let iPhone12: LayoutConfiguration = .iPhone12(.portrait)

    public static func iPhone12(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen6_1v1,
            portraitSafeArea: EdgeInsets(top: 47, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhone12
        )
    }

    public static let iPhone12Mini: LayoutConfiguration = .iPhone12Mini(.portrait)

    public static func iPhone12Mini(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen5_4,
            portraitSafeArea: EdgeInsets(top: 50, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhone12Mini
        )
    }
}

// MARK: - iPhone 11
extension LayoutConfiguration {

    public static let iPhone11ProMax: LayoutConfiguration = .iPhone11ProMax(.portrait)

    public static func iPhone11ProMax(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen6_5,
            portraitSafeArea: EdgeInsets(top: 47, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhone11ProMax
        )
    }

    public static let iPhone11Pro: LayoutConfiguration = .iPhone11Pro(.portrait)

    public static func iPhone11Pro(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen5_8,
            portraitSafeArea: EdgeInsets(top: 47, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhone11Pro
        )
    }

    public static let iPhone11: LayoutConfiguration = .iPhone11(.portrait)

    public static func iPhone11(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen6_1v3,
            portraitSafeArea: EdgeInsets(top: 47, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 2,
            deviceInterfaceSizeClass: .iPhone11ProMax
        )
    }
}

// MARK: - iPhone X
extension LayoutConfiguration {

    public static let iPhoneXR: LayoutConfiguration = .iPhoneXR(.portrait)

    public static func iPhoneXR(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen6_1v3,
            portraitSafeArea: EdgeInsets(top: 44, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhoneXR
        )
    }

    public static let iPhoneXSMax: LayoutConfiguration = .iPhoneXSMax(.portrait)

    public static func iPhoneXSMax(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen6_5,
            portraitSafeArea: EdgeInsets(top: 44, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhoneXSMax
        )
    }

    public static let iPhoneXS: LayoutConfiguration = .iPhoneXS(.portrait)

    public static func iPhoneXS(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen5_8,
            portraitSafeArea: EdgeInsets(top: 44, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhoneXS
        )
    }

    public static let iPhoneX: LayoutConfiguration = .iPhoneX(.portrait)

    public static func iPhoneX(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen5_8,
            portraitSafeArea: EdgeInsets(top: 44, bottom: 34, right: 0),
            orientation: orientation,
            displayScale: 2,
            deviceInterfaceSizeClass: .iPhoneX
        )
    }
}

// MARK: - iPhone 8
extension LayoutConfiguration {

    public static let iPhone8: LayoutConfiguration = .iPhone8(.portrait)

    public static func iPhone8(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen4_7,
            portraitSafeArea: EdgeInsets(top: 20),
            landscapeSafeArea: EdgeInsets.zero,
            orientation: orientation,
            displayScale: 2,
            deviceInterfaceSizeClass: .iPhone8
        )
    }

    public static let iPhone8Plus: LayoutConfiguration = .iPhone8Plus(.portrait)

    public static func iPhone8Plus(_ orientation: DeviceOrientation) -> LayoutConfiguration {
        iPhone(
            size: .screen5_5,
            portraitSafeArea: EdgeInsets(top: 20),
            landscapeSafeArea: EdgeInsets.zero,
            orientation: orientation,
            displayScale: 3,
            deviceInterfaceSizeClass: .iPhone8Plus
        )
    }
}

// MARK: - iPhone SE
extension LayoutConfiguration {

    public static let iPhoneSE: LayoutConfiguration = .iPhoneSE(.portrait)

    public static func iPhoneSE(
        _ orientation: DeviceOrientation
    ) -> LayoutConfiguration {
        iPhone(
            size: .screen4_7,
            portraitSafeArea: EdgeInsets(top: 20),
            landscapeSafeArea: .zero,
            orientation: orientation,
            displayScale: 2,
            deviceInterfaceSizeClass: .iPhoneSE
        )
    }
}

// MARK: - iPhone
extension LayoutConfiguration {

    fileprivate static func iPhone(
        size: CGSize,
        portraitSafeArea: EdgeInsets,
        landscapeSafeArea: EdgeInsets = .init(bottom: 21),
        orientation: DeviceOrientation,
        displayScale: CGFloat,
        deviceInterfaceSizeClass: DeviceDynamicInterfaceSizeClass
    ) -> LayoutConfiguration {
        let safeArea: UIEdgeInsets
        let screenSize: CGSize

        switch orientation {
        case .portrait(let ratio):
            precondition(ratio == .extended)

            safeArea = .init(
                top: portraitSafeArea.top ?? .zero,
                left: portraitSafeArea.left ?? .zero,
                bottom: portraitSafeArea.bottom ?? .zero,
                right: portraitSafeArea.right ?? .zero
            )
            screenSize = size
        case .landscape(let ratio):
            precondition(ratio == .extended)

            safeArea = UIEdgeInsets(
                top: landscapeSafeArea.top ?? .zero,
                left: landscapeSafeArea.left ?? portraitSafeArea.top ?? .zero,
                bottom: landscapeSafeArea.bottom ?? 21,
                right: landscapeSafeArea.right ?? portraitSafeArea.top ?? .zero
            )
            screenSize = size.reflected()
        }

        return .init(
            safeArea: safeArea,
            size: screenSize,
            traits: .iOS(
                displayScale: displayScale,
                size: screenSize,
                deviceInterfaceSizeClass: deviceInterfaceSizeClass
            )
        )
    }
}

// MARK: - iPad Pro
extension LayoutConfiguration {

    public static let iPadPro12_9 = iPadPro12_9(.landscape)

    public static func iPadPro12_9(
        _ orientation: DeviceOrientation
    ) -> LayoutConfiguration {
        iPad(
            orientation: orientation,
            size: CGSize(width: 1_024, height: 1_366),
            displayScale: 2,
            deviceInterfaceSizeClass: .iPadOS
        )
    }

    public static let iPadPro11 = iPadPro11(.landscape)

    public static func iPadPro11(
        _ orientation: DeviceOrientation
    ) -> LayoutConfiguration {
        iPad(
            orientation: orientation,
            size: CGSize(width: 834, height: 1_194),
            displayScale: 2,
            deviceInterfaceSizeClass: .iPadOS
        )
    }

    public static let iPadPro10_5 = iPadPro10_5(.landscape)

    public static func iPadPro10_5(
        _ orientation: DeviceOrientation
    ) -> LayoutConfiguration {
        iPad(
            orientation: orientation,
            size: CGSize(width: 834, height: 1_194),
            displayScale: 2,
            deviceInterfaceSizeClass: .iPadOS
        )
    }

    public static let iPadPro9_7 = iPadPro9_7(.landscape)

    public static func iPadPro9_7(
        _ orientation: DeviceOrientation
    ) -> LayoutConfiguration {
        iPad(
            orientation: orientation,
            size: CGSize(width: 768, height: 1_024),
            displayScale: 2,
            deviceInterfaceSizeClass: .iPadOS
        )
    }
}

// MARK: - iPad Air
extension LayoutConfiguration {

    public static let iPadAir13 = iPadAir13(.landscape)

    public static func iPadAir13(
        _ orientation: DeviceOrientation
    ) -> LayoutConfiguration {
        iPad(
            orientation: orientation,
            size: CGSize(width: 1_024, height: 1_366),
            displayScale: 2,
            deviceInterfaceSizeClass: .iPadOS
        )
    }

    public static let iPadAir11 = iPadAir11(.landscape)

    public static func iPadAir11(
        _ orientation: DeviceOrientation
    ) -> LayoutConfiguration {
        iPad(
            orientation: orientation,
            size: CGSize(width: 820, height: 1_180),
            displayScale: 2,
            deviceInterfaceSizeClass: .iPadOS
        )
    }

    public static let iPadAir10_9 = iPadAir10_9(.landscape)

    public static func iPadAir10_9(
        _ orientation: DeviceOrientation
    ) -> LayoutConfiguration {
        iPad(
            orientation: orientation,
            size: CGSize(width: 820, height: 1_180),
            displayScale: 2,
            deviceInterfaceSizeClass: .iPadOS
        )
    }

    public static let iPadAir10_5 = iPadAir10_5(.landscape)

    public static func iPadAir10_5(
        _ orientation: DeviceOrientation
    ) -> LayoutConfiguration {
        iPad(
            orientation: orientation,
            size: CGSize(width: 820, height: 1_180),
            displayScale: 2,
            deviceInterfaceSizeClass: .iPadOS
        )
    }

    public static let iPadAir9_7 = iPadAir9_7(.landscape)

    public static func iPadAir9_7(
        _ orientation: DeviceOrientation
    ) -> LayoutConfiguration {
        iPad(
            orientation: orientation,
            size: CGSize(width: 768, height: 1_024),
            displayScale: 2,
            deviceInterfaceSizeClass: .iPadOS
        )
    }
}

// MARK: - iPad
extension LayoutConfiguration {

    public static let iPad11 = iPad11(.landscape)

    public static func iPad11(
        _ orientation: DeviceOrientation
    ) -> LayoutConfiguration {
        iPad(
            orientation: orientation,
            size: CGSize(width: 820, height: 1_180),
            displayScale: 2,
            deviceInterfaceSizeClass: .iPadOS
        )
    }

    public static let iPad10_2 = iPad10_2(.landscape)

    public static func iPad10_2(
        _ orientation: DeviceOrientation
    ) -> LayoutConfiguration {
        iPad(
            orientation: orientation,
            size: CGSize(width: 810, height: 1_080),
            displayScale: 2,
            deviceInterfaceSizeClass: .iPadOS
        )
    }

    public static let iPad9_7 = iPad9_7(.landscape)

    public static func iPad9_7(
        _ orientation: DeviceOrientation
    ) -> LayoutConfiguration {
        iPad(
            orientation: orientation,
            size: CGSize(width: 768, height: 1_024),
            displayScale: 2,
            deviceInterfaceSizeClass: .iPadOS
        )
    }
}

// MARK: - iPad Mini
extension LayoutConfiguration {

    public static let iPadMini8_3 = iPadMini8_3(.landscape)

    public static func iPadMini8_3(
        _ orientation: DeviceOrientation
    ) -> LayoutConfiguration {
        iPad(
            orientation: orientation,
            size: CGSize(width: 744, height: 1_133),
            displayScale: 2,
            deviceInterfaceSizeClass: .iPadOS
        )
    }

    public static let iPadMini7_9 = iPadMini7_9(.landscape)

    public static func iPadMini7_9(
        _ orientation: DeviceOrientation
    ) -> LayoutConfiguration {
        iPad(
            orientation: orientation,
            size: CGSize(width: 768, height: 1_024),
            displayScale: 2,
            deviceInterfaceSizeClass: .iPadOS
        )
    }
}

// MARK: - iPad Method
extension LayoutConfiguration {

    fileprivate static func iPad(
        orientation: DeviceOrientation,
        size: CGSize,
        displayScale: CGFloat,
        deviceInterfaceSizeClass: DeviceDynamicInterfaceSizeClass
    ) -> LayoutConfiguration {
        var deviceSize: CGSize
        let deviceRatio: DeviceLayoutRatio

        switch orientation {
        case .landscape(let ratio):
            deviceRatio = ratio
            deviceSize = size.reflected()
        case .portrait(let ratio):
            deviceRatio = ratio
            deviceSize = size
        }

        deviceSize.width *= deviceRatio.rawValue

        return LayoutConfiguration(
            safeArea: UIEdgeInsets(top: 24, left: .zero, bottom: 20, right: .zero),
            size: deviceSize,
            traits: .iPadOS(
                displayScale: displayScale,
                size: deviceSize,
                deviceInterfaceSizeClass: deviceInterfaceSizeClass
            )
        )
    }
}

extension LayoutConfiguration {

    public static let tv = tvOS(
        displayScale: 1,
        deviceInterfaceSizeClass: .tvOS
    )

    public static let tv4K = tvOS(
        displayScale: 2,
        deviceInterfaceSizeClass: .tvOS
    )

    private static func tvOS(
        displayScale: CGFloat,
        deviceInterfaceSizeClass: DeviceDynamicInterfaceSizeClass
    ) -> LayoutConfiguration {
        let size = CGSize(width: 1920, height: 1080)

        return LayoutConfiguration(
            safeArea: .init(top: 60, left: 80, bottom: 60, right: 80),
            size: size,
            traits: .tvOS(
                displayScale: displayScale,
                size: size,
                deviceInterfaceSizeClass: deviceInterfaceSizeClass
            )
        )
    }
}
#endif
#endif
