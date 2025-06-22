import Foundation

#if os(iOS)
  import UIKit
#endif

private struct PlatformEnvironmentKey: SnapshotEnvironmentKey {

  static var defaultValue: String {
    TestingSystem.shared.environment?.platform ?? operatingSystemName()
  }

  private static func operatingSystemName() -> String {
    #if os(macOS)
      return "macOS"
    #elseif os(iOS)
      return performOnMainThread {
        if UIDevice.current.userInterfaceIdiom == .pad {
          return "iPadOS"
        } else {
          return "iOS"
        }
      }
    #elseif os(tvOS)
      return "tvOS"
    #elseif os(watchOS)
      return "watchOS"
    #elseif os(visionOS)
      return "visionOS"
    #elseif os(Android)
      return "android"
    #elseif os(Windows)
      return "windows"
    #elseif os(Linux)
      return "linux"
    #elseif os(WASI)
      return "wasi"
    #else
      return "unknown"
    #endif
  }
}

extension SnapshotEnvironmentValues {

  public var platform: String {
    get { self[PlatformEnvironmentKey.self] }
    set { self[PlatformEnvironmentKey.self] = newValue }
  }
}
