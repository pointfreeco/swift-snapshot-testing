import Foundation

extension Platform {
  /// The rendering-relevant traits of a simulator device type.
  ///
  /// `name` and `modelIdentifier` match `xcrun simctl list devicetypes` and the
  /// `modelIdentifier` key of the device type's `profile.plist` respectively. Scale also
  /// appears in `profile.plist` (`mainScreenScale`), but gamut is exposed by no CoreSimulator
  /// metadata, so it is maintained here. Rule of thumb: P3 for iPhone 7 and later; sRGB for
  /// base-model iPads (through iPad (A16)), P3 for iPad Pro (from the 9.7-inch), iPad Air
  /// (from the 3rd generation), and iPad mini (from the 5th generation).
  ///
  /// KEEP IN SYNC with the gamut table in scripts/snapshot-simulators.swift.
  public struct SimulatedDevice {
    public let name: String
    public let modelIdentifier: String
    public let os: OS
    public let gamut: Gamut
    public let scale: Int

    public init(name: String, modelIdentifier: String, os: OS, gamut: Gamut, scale: Int) {
      self.name = name
      self.modelIdentifier = modelIdentifier
      self.os = os
      self.gamut = gamut
      self.scale = scale
    }
  }

  /// The platform of a given iOS simulator device type and OS version, e.g.
  ///
  ///     supportedPlatforms = [Platform.iOSSimulator(named: "iPhone 16e", version: "18.5")!]
  ///
  /// Returns nil for device type names not in `knownSimulatedDevices`.
  public static func iOSSimulator(named name: String, version: String) -> Platform? {
    return simulator(os: .iOS, named: name, version: version)
  }

  /// The platform of a given tvOS simulator device type and OS version. Returns nil for
  /// device type names not in `knownSimulatedDevices`.
  public static func tvOSSimulator(named name: String, version: String) -> Platform? {
    return simulator(os: .tvOS, named: name, version: version)
  }

  private static func simulator(os: OS, named name: String, version: String) -> Platform? {
    guard let device = knownSimulatedDevices.first(where: { $0.os == os && $0.name == name })
    else { return nil }
    return Platform(os: os, version: version, gamut: device.gamut, scale: device.scale)
  }

  /// Simulator device types shipped with Xcode, with their rendering-relevant traits.
  /// Derived from the device type profiles under
  /// /Library/Developer/CoreSimulator/Profiles/DeviceTypes (scale, model identifier) and
  /// Apple's published display specifications (gamut).
  public static let knownSimulatedDevices: [SimulatedDevice] = [
    // iPhone
    .init(name: "iPhone 6s", modelIdentifier: "iPhone8,1", os: .iOS, gamut: .srgb, scale: 2),
    .init(name: "iPhone 6s Plus", modelIdentifier: "iPhone8,2", os: .iOS, gamut: .srgb, scale: 3),
    .init(
      name: "iPhone SE (1st generation)", modelIdentifier: "iPhone8,4", os: .iOS, gamut: .srgb,
      scale: 2),
    .init(name: "iPhone 7", modelIdentifier: "iPhone9,1", os: .iOS, gamut: .p3, scale: 2),
    .init(name: "iPhone 7 Plus", modelIdentifier: "iPhone9,2", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 8", modelIdentifier: "iPhone10,4", os: .iOS, gamut: .p3, scale: 2),
    .init(name: "iPhone 8 Plus", modelIdentifier: "iPhone10,5", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone X", modelIdentifier: "iPhone10,6", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone Xs", modelIdentifier: "iPhone11,2", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone Xs Max", modelIdentifier: "iPhone11,4", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone Xʀ", modelIdentifier: "iPhone11,8", os: .iOS, gamut: .p3, scale: 2),
    .init(name: "iPhone 11", modelIdentifier: "iPhone12,1", os: .iOS, gamut: .p3, scale: 2),
    .init(name: "iPhone 11 Pro", modelIdentifier: "iPhone12,3", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 11 Pro Max", modelIdentifier: "iPhone12,5", os: .iOS, gamut: .p3, scale: 3),
    .init(
      name: "iPhone SE (2nd generation)", modelIdentifier: "iPhone12,8", os: .iOS, gamut: .p3,
      scale: 2),
    .init(name: "iPhone 12 mini", modelIdentifier: "iPhone13,1", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 12", modelIdentifier: "iPhone13,2", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 12 Pro", modelIdentifier: "iPhone13,3", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 12 Pro Max", modelIdentifier: "iPhone13,4", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 13 Pro", modelIdentifier: "iPhone14,2", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 13 Pro Max", modelIdentifier: "iPhone14,3", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 13 mini", modelIdentifier: "iPhone14,4", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 13", modelIdentifier: "iPhone14,5", os: .iOS, gamut: .p3, scale: 3),
    .init(
      name: "iPhone SE (3rd generation)", modelIdentifier: "iPhone14,6", os: .iOS, gamut: .p3,
      scale: 2),
    .init(name: "iPhone 14", modelIdentifier: "iPhone14,7", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 14 Plus", modelIdentifier: "iPhone14,8", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 14 Pro", modelIdentifier: "iPhone15,2", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 14 Pro Max", modelIdentifier: "iPhone15,3", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 15", modelIdentifier: "iPhone15,4", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 15 Plus", modelIdentifier: "iPhone15,5", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 15 Pro", modelIdentifier: "iPhone16,1", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 15 Pro Max", modelIdentifier: "iPhone16,2", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 16 Pro", modelIdentifier: "iPhone17,1", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 16 Pro Max", modelIdentifier: "iPhone17,2", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 16", modelIdentifier: "iPhone17,3", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 16 Plus", modelIdentifier: "iPhone17,4", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 16e", modelIdentifier: "iPhone17,5", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 17 Pro", modelIdentifier: "iPhone18,1", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 17 Pro Max", modelIdentifier: "iPhone18,2", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 17", modelIdentifier: "iPhone18,3", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone Air", modelIdentifier: "iPhone18,4", os: .iOS, gamut: .p3, scale: 3),
    .init(name: "iPhone 17e", modelIdentifier: "iPhone18,5", os: .iOS, gamut: .p3, scale: 3),
    .init(
      name: "iPod touch (7th generation)", modelIdentifier: "iPod9,1", os: .iOS, gamut: .srgb,
      scale: 2),
    // iPad
    .init(name: "iPad mini 4", modelIdentifier: "iPad5,1", os: .iOS, gamut: .srgb, scale: 2),
    .init(name: "iPad Air 2", modelIdentifier: "iPad5,4", os: .iOS, gamut: .srgb, scale: 2),
    .init(name: "iPad Pro (9.7-inch)", modelIdentifier: "iPad6,4", os: .iOS, gamut: .p3, scale: 2),
    .init(
      name: "iPad Pro (12.9-inch) (1st generation)", modelIdentifier: "iPad6,8", os: .iOS,
      gamut: .srgb, scale: 2),
    .init(
      name: "iPad (5th generation)", modelIdentifier: "iPad6,12", os: .iOS, gamut: .srgb, scale: 2),
    .init(
      name: "iPad Pro (12.9-inch) (2nd generation)", modelIdentifier: "iPad7,1", os: .iOS,
      gamut: .p3, scale: 2),
    .init(name: "iPad Pro (10.5-inch)", modelIdentifier: "iPad7,3", os: .iOS, gamut: .p3, scale: 2),
    .init(
      name: "iPad (6th generation)", modelIdentifier: "iPad7,6", os: .iOS, gamut: .srgb, scale: 2),
    .init(
      name: "iPad (7th generation)", modelIdentifier: "iPad7,12", os: .iOS, gamut: .srgb, scale: 2),
    .init(
      name: "iPad Pro (11-inch) (1st generation)", modelIdentifier: "iPad8,1", os: .iOS, gamut: .p3,
      scale: 2),
    .init(
      name: "iPad Pro (12.9-inch) (3rd generation)", modelIdentifier: "iPad8,5", os: .iOS,
      gamut: .p3, scale: 2),
    .init(
      name: "iPad Pro (11-inch) (2nd generation)", modelIdentifier: "iPad8,9", os: .iOS, gamut: .p3,
      scale: 2),
    .init(
      name: "iPad Pro (12.9-inch) (4th generation)", modelIdentifier: "iPad8,12", os: .iOS,
      gamut: .p3, scale: 2),
    .init(
      name: "iPad mini (5th generation)", modelIdentifier: "iPad11,1", os: .iOS, gamut: .p3,
      scale: 2),
    .init(
      name: "iPad Air (3rd generation)", modelIdentifier: "iPad11,3", os: .iOS, gamut: .p3, scale: 2
    ),
    .init(
      name: "iPad (8th generation)", modelIdentifier: "iPad11,7", os: .iOS, gamut: .srgb, scale: 2),
    .init(
      name: "iPad (9th generation)", modelIdentifier: "iPad12,2", os: .iOS, gamut: .srgb, scale: 2),
    .init(
      name: "iPad Air (4th generation)", modelIdentifier: "iPad13,2", os: .iOS, gamut: .p3, scale: 2
    ),
    .init(
      name: "iPad Pro (11-inch) (3rd generation)", modelIdentifier: "iPad13,5", os: .iOS,
      gamut: .p3, scale: 2),
    .init(
      name: "iPad Pro (12.9-inch) (5th generation)", modelIdentifier: "iPad13,10", os: .iOS,
      gamut: .p3, scale: 2),
    .init(
      name: "iPad Air (5th generation)", modelIdentifier: "iPad13,17", os: .iOS, gamut: .p3,
      scale: 2),
    .init(
      name: "iPad (10th generation)", modelIdentifier: "iPad13,18", os: .iOS, gamut: .srgb, scale: 2
    ),
    .init(
      name: "iPad mini (6th generation)", modelIdentifier: "iPad14,1", os: .iOS, gamut: .p3,
      scale: 2),
    .init(
      name: "iPad Pro (11-inch) (4th generation)", modelIdentifier: "iPad14,3", os: .iOS,
      gamut: .p3, scale: 2),
    .init(
      name: "iPad Pro (11-inch) (4th generation) (16GB)", modelIdentifier: "iPad14,4", os: .iOS,
      gamut: .p3, scale: 2),
    .init(
      name: "iPad Pro (12.9-inch) (6th generation)", modelIdentifier: "iPad14,5", os: .iOS,
      gamut: .p3, scale: 2),
    .init(
      name: "iPad Pro (12.9-inch) (6th generation) (16GB)", modelIdentifier: "iPad14,5", os: .iOS,
      gamut: .p3, scale: 2),
    .init(
      name: "iPad Air 11-inch (M2)", modelIdentifier: "iPad14,9", os: .iOS, gamut: .p3, scale: 2),
    .init(
      name: "iPad Air 13-inch (M2)", modelIdentifier: "iPad14,11", os: .iOS, gamut: .p3, scale: 2),
    .init(
      name: "iPad Air 11-inch (M3)", modelIdentifier: "iPad15,3", os: .iOS, gamut: .p3, scale: 2),
    .init(
      name: "iPad Air 13-inch (M3)", modelIdentifier: "iPad15,5", os: .iOS, gamut: .p3, scale: 2),
    .init(name: "iPad (A16)", modelIdentifier: "iPad15,7", os: .iOS, gamut: .srgb, scale: 2),
    .init(name: "iPad mini (A17 Pro)", modelIdentifier: "iPad16,2", os: .iOS, gamut: .p3, scale: 2),
    .init(
      name: "iPad Pro 11-inch (M4)", modelIdentifier: "iPad16,4", os: .iOS, gamut: .p3, scale: 2),
    .init(
      name: "iPad Pro 11-inch (M4) (16GB)", modelIdentifier: "iPad16,4", os: .iOS, gamut: .p3,
      scale: 2),
    .init(
      name: "iPad Pro 13-inch (M4)", modelIdentifier: "iPad16,6", os: .iOS, gamut: .p3, scale: 2),
    .init(
      name: "iPad Pro 13-inch (M4) (16GB)", modelIdentifier: "iPad16,6", os: .iOS, gamut: .p3,
      scale: 2),
    .init(
      name: "iPad Air 11-inch (M4)", modelIdentifier: "iPad16,9", os: .iOS, gamut: .p3, scale: 2),
    .init(
      name: "iPad Air 13-inch (M4)", modelIdentifier: "iPad16,11", os: .iOS, gamut: .p3, scale: 2),
    .init(
      name: "iPad Pro 11-inch (M5)", modelIdentifier: "iPad17,2", os: .iOS, gamut: .p3, scale: 2),
    .init(
      name: "iPad Pro 11-inch (M5) (16GB)", modelIdentifier: "iPad17,2", os: .iOS, gamut: .p3,
      scale: 2),
    .init(
      name: "iPad Pro 13-inch (M5)", modelIdentifier: "iPad17,4", os: .iOS, gamut: .p3, scale: 2),
    .init(
      name: "iPad Pro 13-inch (M5) (16GB)", modelIdentifier: "iPad17,4", os: .iOS, gamut: .p3,
      scale: 2),
    // Apple TV — gamut unverified (depends on the simulated display); confirm by reading
    // Platform().rawValue on a tvOS simulator before relying on these entries.
    .init(
      name: "Apple TV", modelIdentifier: "AppleTV5,3", os: .tvOS, gamut: .unspecified, scale: 1),
    .init(
      name: "Apple TV 4K", modelIdentifier: "AppleTV6,2", os: .tvOS, gamut: .unspecified, scale: 2),
    .init(
      name: "Apple TV 4K (at 1080p)", modelIdentifier: "AppleTV6,2", os: .tvOS, gamut: .unspecified,
      scale: 1),
    .init(
      name: "Apple TV 4K (2nd generation)", modelIdentifier: "AppleTV11,1", os: .tvOS,
      gamut: .unspecified, scale: 2),
    .init(
      name: "Apple TV 4K (2nd generation) (at 1080p)", modelIdentifier: "AppleTV11,1", os: .tvOS,
      gamut: .unspecified, scale: 1),
    .init(
      name: "Apple TV 4K (3rd generation)", modelIdentifier: "AppleTV14,1", os: .tvOS,
      gamut: .unspecified, scale: 2),
    .init(
      name: "Apple TV 4K (3rd generation) (at 1080p)", modelIdentifier: "AppleTV14,1", os: .tvOS,
      gamut: .unspecified, scale: 1),
  ]
}
