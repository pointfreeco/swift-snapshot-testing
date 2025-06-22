import Foundation

private struct PlatformEnvironmentKey: SnapshotEnvironmentKey {

  static var defaultValue: String {
    TestingSystem.shared.environment?.platform ?? operatingSystemName()
  }

  private static func operatingSystemName() -> String {
    #if os(macOS)
      return "macOS"
    #elseif os(iOS)
      return "iOS"
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
      return "wasm"
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
