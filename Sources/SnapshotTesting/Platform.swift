import Foundation
#if canImport(UIKit)
import UIKit
#endif

public struct Platform: Equatable {
  let os: OS
  let version: String
  let gamut: Gamut
  let scale: Int

  enum Gamut: String {
    case unspecified
    case SRGB = "srgb"
    case P3 = "p3"

    init(from gamut: UIDisplayGamut) {
      switch gamut {
      case .unspecified: self = .unspecified
      case .SRGB: self = .SRGB
      case .P3: self = .P3
      }
    }
  }

  enum OS: String {
    case iOS, macOS, tvOS, linux

    init() {
      #if os(iOS)
      self = .iOS
      #endif
      #if os(macOS)
      self = .macOS
      #endif
      #if os(tvOS)
      self = .tvOS
      #endif
      #if os(Linux)
      self = .linux
      #endif
    }
  }
}

extension Platform {
  internal init() {
    os = OS()
    version = ProcessInfo().operatingSystemVersion.pretty
    #if os(Linux)
    gamut = .unspecified
    scale = 0 // "unspecified" in UITraitCollection.displayScale
    #endif
    #if os(iOS) || os(tvOS)
    let traits = UIScreen.main.traitCollection
    gamut = Gamut(from: traits.displayGamut)
    scale = Int(traits.displayScale)
    #endif
    #if os(macOS)
    // TODO (no trait collection, gamut especially seems to have to read API?)
    #endif
  }
}

extension OperatingSystemVersion {
  fileprivate var pretty: String {
    return patchVersion == 0 ? "\(majorVersion).\(minorVersion)" : "\(majorVersion).\(minorVersion).\(patchVersion)"
  }
}

extension Platform: RawRepresentable {
  public var rawValue: String {
    return "\(os)-\(version)-\(gamut.rawValue)@\(scale)x"
  }

  public init?(rawValue: String) {
    let components = rawValue.split(separator: "-")
    guard components.count == 3 else { return nil }
    guard let os = OS(rawValue: String(components[0])) else { return nil }
    guard components[2].last == "x" else { return nil } // FIXME: oh come on this is ridiculous
    let imageStuff = components[2].dropLast().split(separator: "@")
    guard imageStuff.count == 2 else { return nil }
    guard let gamut = Gamut(rawValue: String(imageStuff[0])) else { return nil }
    guard let scale = Int(imageStuff[1]) else { return nil }
    self.os = os
    self.gamut = gamut
    self.version = String(components[1]) // FIXME: validate it's a version-string?
    self.scale = scale
  }
}

extension Platform {
  public static let iPhone5sSimulator_12_1 = Platform(os: .iOS, version: "12.1", gamut: .SRGB, scale: 2)
  public static let iPhoneXrSimulator_12_1 = Platform(os: .iOS, version: "12.1", gamut: .P3, scale: 2)
}
