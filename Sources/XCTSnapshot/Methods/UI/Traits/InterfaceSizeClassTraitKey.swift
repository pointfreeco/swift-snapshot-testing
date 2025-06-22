#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
  import UIKit
#elseif os(macOS)
  @preconcurrency import AppKit
#endif

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
  public enum InterfaceSizeClass: Sendable, Hashable {
    case unspecified
    case regular
    case compact
  }

  public struct DeviceInterfaceSizeClass: Sendable, Hashable {

    public let horizontal: InterfaceSizeClass
    public let vertical: InterfaceSizeClass

    public init(horizontal: InterfaceSizeClass, vertical: InterfaceSizeClass) {
      self.horizontal = horizontal
      self.vertical = vertical
    }
  }

  public struct DeviceDynamicInterfaceSizeClass: Sendable {

    private let provider: @Sendable (CGSize) -> DeviceInterfaceSizeClass

    public init(provider: @escaping @Sendable (CGSize) -> DeviceInterfaceSizeClass) {
      self.provider = provider
    }

    public init(constant: DeviceInterfaceSizeClass) {
      self.init(provider: { _ in constant })
    }

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

      public var deviceInterfaceSizeClass: DeviceInterfaceSizeClass {
        get { self[DeviceInterfaceSizeClassTraitKey.self] }
        set { self[DeviceInterfaceSizeClassTraitKey.self] = newValue }
      }

      public init(deviceInterfaceSizeClass: DeviceInterfaceSizeClass) {
        self.init()
        self.deviceInterfaceSizeClass = deviceInterfaceSizeClass
      }
    }
  #endif
#endif
