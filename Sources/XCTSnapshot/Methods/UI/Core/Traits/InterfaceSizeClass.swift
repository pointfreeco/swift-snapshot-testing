#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
#elseif os(macOS)
@preconcurrency import AppKit
#endif

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
public enum InterfaceSizeClass: Sendable {
  case regular
  case compact
}

public struct DeviceInterfaceSizeClass: Sendable {

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
public extension DeviceDynamicInterfaceSizeClass {

  // MARK: - iPhone 16

  static let iPhone16ProMax = withRegularLandscape

  static let iPhone16Pro = withCompactLandscape

  static let iPhone16Plus = withRegularLandscape

  static let iPhone16 = withCompactLandscape

  static let iPhone16e = withCompactLandscape

  // MARK: - iPhone 15

  static let iPhone15ProMax = withRegularLandscape

  static let iPhone15Pro = withCompactLandscape

  static let iPhone15Plus = withRegularLandscape

  static let iPhone15 = withCompactLandscape

  // MARK: - iPhone 14

  static let iPhone14ProMax = withRegularLandscape

  static let iPhone14Pro = withCompactLandscape

  static let iPhone14Plus = withRegularLandscape

  static let iPhone14 = withCompactLandscape

  // MARK: - iPhone 13

  static let iPhone13ProMax = withRegularLandscape

  static let iPhone13Pro = withCompactLandscape

  static let iPhone13 = withCompactLandscape

  static let iPhone13Mini = withCompactLandscape

  // MARK: - iPhone 12

  static let iPhone12ProMax = withRegularLandscape

  static let iPhone12Pro = withCompactLandscape

  static let iPhone12 = withCompactLandscape

  static let iPhone12Mini = withCompactLandscape

  // MARK: - iPhone 11

  static let iPhone11ProMax = withRegularLandscape

  static let iPhone11Pro = withCompactLandscape

  static let iPhone11 = withRegularLandscape

  // MARK: - iPhone XS

  static let iPhoneXSMax = withRegularLandscape

  static let iPhoneXS = withCompactLandscape

  // MARK: - iPhone XR

  static let iPhoneXR = withRegularLandscape

  // MARK: - iPhone X

  static let iPhoneX = withCompactLandscape

  // MARK: - iPhone 8

  static let iPhone8Plus = withRegularLandscape

  static let iPhone8 = withCompactLandscape

  // MARK: - iPhone SE

  static let iPhoneSE = withCompactLandscape

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
public extension DeviceDynamicInterfaceSizeClass {

  static let iPadOS = DeviceDynamicInterfaceSizeClass { size in
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
public extension DeviceDynamicInterfaceSizeClass {

  static let macOS = DeviceDynamicInterfaceSizeClass(
    constant: DeviceInterfaceSizeClass(horizontal: .regular, vertical: .regular)
  )

  static let tvOS = DeviceDynamicInterfaceSizeClass(
    constant: DeviceInterfaceSizeClass(horizontal: .regular, vertical: .regular)
  )

  static let visionOS = DeviceDynamicInterfaceSizeClass(
    constant: DeviceInterfaceSizeClass(horizontal: .regular, vertical: .regular)
  )
}

// MARK: - WatchOS
public extension DeviceDynamicInterfaceSizeClass {

  static let watchOS = DeviceDynamicInterfaceSizeClass(
    constant: DeviceInterfaceSizeClass(horizontal: .compact, vertical: .compact)
  )
}

#if os(iOS) || os(tvOS)
extension Traits {

  public convenience init(deviceInterfaceSizeClass: DeviceInterfaceSizeClass) {
    let verticalSizeClass = Self.userInterfaceSizeClass(deviceInterfaceSizeClass.vertical)
    let horizontalSizeClass = Self.userInterfaceSizeClass(deviceInterfaceSizeClass.horizontal)

    self.init(traitsFrom: [
      UITraitCollection(verticalSizeClass: verticalSizeClass),
      UITraitCollection(horizontalSizeClass: horizontalSizeClass)
    ])
  }
}
#endif

#if os(visionOS)
extension Traits {

  public init(deviceInterfaceSizeClass: DeviceInterfaceSizeClass) {
    let verticalSizeClass = Self.userInterfaceSizeClass(deviceInterfaceSizeClass.vertical)
    let horizontalSizeClass = Self.userInterfaceSizeClass(deviceInterfaceSizeClass.horizontal)

    self.init {
      $0.verticalSizeClass = verticalSizeClass
      $0.horizontalSizeClass = horizontalSizeClass
    }
  }
}
#endif

#if os(iOS) || os(tvOS) || os(visionOS)
extension Traits {

  fileprivate static func userInterfaceSizeClass(
    _ interfaceSizeClass: InterfaceSizeClass
  ) -> UIUserInterfaceSizeClass {
    switch interfaceSizeClass {
    case .compact:
      return .compact
    case .regular:
      return .regular
    }
  }
}
#endif
#endif
