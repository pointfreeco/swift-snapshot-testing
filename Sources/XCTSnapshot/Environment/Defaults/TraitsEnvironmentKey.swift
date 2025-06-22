import Foundation

#if os(iOS) || os(tvOS) || os(visionOS)
  import UIKit

  private struct TraitsEnvironmentKey: SnapshotEnvironmentKey {
    static let defaultValue = Traits()
  }

  extension SnapshotEnvironmentValues {

    public var traits: Traits {
      get { self[TraitsEnvironmentKey.self] }
      set { self[TraitsEnvironmentKey.self] = newValue }
    }
  }
#endif
