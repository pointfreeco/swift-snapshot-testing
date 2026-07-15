import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// The rendering-relevant identity of the environment a snapshot was recorded on: operating
/// system, OS version, display gamut, and display scale.
///
/// Two simulators with equal `Platform`s render pixel-identical snapshots, so they share
/// reference files; snapshots record which platform they were taken on via
/// `rawValue` (e.g. `"iOS-18.5-p3@3x"`) embedded in their filename.
public struct Platform: Equatable, Hashable {
  public let os: OS
  public let version: String
  public let gamut: Gamut
  public let scale: Int

  /// - Parameter version: Normalized on the way in: at least `major.minor`, with trailing
  ///   zero components beyond that dropped (`"18.5.0"` is stored as `"18.5"`).
  public init(os: OS, version: String, gamut: Gamut, scale: Int) {
    self.os = os
    self.version = Platform.normalize(version: version)
    self.gamut = gamut
    self.scale = scale
  }

  public enum Gamut: String, CaseIterable {
    case unspecified
    case srgb
    case p3

    #if canImport(UIKit) && !os(watchOS)
    init(from gamut: UIDisplayGamut) {
      switch gamut {
      case .unspecified: self = .unspecified
      case .SRGB: self = .srgb
      case .P3: self = .p3
      @unknown default: self = .unspecified
      }
    }
    #endif
  }

  public enum OS: String, CaseIterable {
    case iOS, macOS, tvOS, linux

    init() {
      #if os(iOS)
      self = .iOS
      #elseif os(macOS)
      self = .macOS
      #elseif os(tvOS)
      self = .tvOS
      #elseif os(Linux)
      self = .linux
      #endif
    }
  }
}

extension Platform {
  /// The platform of the currently running environment.
  internal init() {
    let osVersion = ProcessInfo().operatingSystemVersion
    let version = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
    #if os(iOS) || os(tvOS)
    let traits = UIScreen.main.traitCollection
    self.init(
      os: OS(),
      version: version,
      gamut: Gamut(from: traits.displayGamut),
      scale: Int(traits.displayScale)
    )
    #elseif os(macOS)
    self.init(
      os: OS(),
      version: version,
      gamut: .unspecified,
      scale: Int(NSScreen.main?.backingScaleFactor ?? 1)
    )
    #else
    self.init(
      os: OS(),
      version: version,
      gamut: .unspecified,
      scale: 0 // "unspecified" in UITraitCollection.displayScale
    )
    #endif
  }

  /// Normalizes a version string for comparison and display: pads to at least
  /// `major.minor`, then drops trailing zero components beyond that
  /// (`"18"` → `"18.0"`, `"18.5.0"` → `"18.5"`, `"26.3.1"` unchanged).
  internal static func normalize(version: String) -> String {
    var components = version.split(separator: ".").map(String.init)
    while components.count > 2, components.last == "0" {
      components.removeLast()
    }
    while components.count < 2 {
      components.append("0")
    }
    return components.joined(separator: ".")
  }
}

extension Platform: RawRepresentable {
  /// e.g. `"iOS-18.5-p3@3x"`. This string is embedded in snapshot filenames.
  public var rawValue: String {
    return "\(os.rawValue)-\(version)-\(gamut.rawValue)@\(scale)x"
  }

  public init?(rawValue: String) {
    let fullRange = NSRange(rawValue.startIndex..., in: rawValue)
    guard let match = Platform.rawValueExpression.firstMatch(in: rawValue, range: fullRange)
      else { return nil }
    func group(_ index: Int) -> String {
      guard let range = Range(match.range(at: index), in: rawValue) else { return "" }
      return String(rawValue[range])
    }
    guard
      let os = OS(rawValue: group(1)),
      let gamut = Gamut(rawValue: group(3)),
      let scale = Int(group(4))
      else { return nil }
    self.init(os: os, version: group(2), gamut: gamut, scale: scale)
  }

  /// Anchored expression for the `rawValue` format. The os and gamut alternations are built
  /// from `allCases` so the parser cannot drift from the enums.
  private static let rawValueExpression: NSRegularExpression = {
    let osCases = OS.allCases.map { $0.rawValue }.joined(separator: "|")
    let gamutCases = Gamut.allCases.map { $0.rawValue }.joined(separator: "|")
    let pattern = "\\A(\(osCases))-([0-9]+(?:\\.[0-9]+){0,2})-(\(gamutCases))@([0-9]+)x\\z"
    return try! NSRegularExpression(pattern: pattern)
  }()
}

extension Platform {
  /// If `fileName` (e.g. `"testFoo-1-iOS-18.5-p3@3x.png"`) is a platform-suffixed snapshot
  /// for the given test name and identifier, returns the platform it was recorded on.
  internal static func ofSnapshot(
    fileNamed fileName: String, testName: String, identifier: String
  ) -> Platform? {
    let basename = (fileName as NSString).deletingPathExtension
    let prefix = "\(testName)-\(identifier)-"
    guard basename.hasPrefix(prefix) else { return nil }
    return Platform(rawValue: String(basename.dropFirst(prefix.count)))
  }
}
