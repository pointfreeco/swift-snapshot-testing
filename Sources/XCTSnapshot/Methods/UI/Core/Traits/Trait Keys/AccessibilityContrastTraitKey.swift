#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit

private struct AccessibilityContrastTraitKey: TraitKey {

  static let defaultValue = UIAccessibilityContrast.unspecified

  @available(iOS 17, tvOS 17, *)
  static func apply(
    _ value: Value,
    to traitsOverrides: inout UITraitOverrides
  ) {
    traitsOverrides.accessibilityContrast = value
  }

  static func apply(_ value: Value, to traitCollection: inout UITraitCollection) {
    #if os(visionOS)
    traitCollection = traitCollection.modifyingTraits {
      $0.accessibilityContrast = value
    }
    #else
    if #available(iOS 17, tvOS 17, *) {
      traitCollection = traitCollection.modifyingTraits {
        $0.accessibilityContrast = value
      }
    } else {
      traitCollection = .init(traitsFrom: [
        traitCollection,
        UITraitCollection(accessibilityContrast: value)
      ])
    }
    #endif
  }
}

extension Traits {

  public var accessibilityContrast: UIAccessibilityContrast {
    get { self[AccessibilityContrastTraitKey.self] }
    set { self[AccessibilityContrastTraitKey.self] = newValue }
  }

  public init(accessibilityContrast: UIAccessibilityContrast) {
    self.init()
    self.accessibilityContrast = accessibilityContrast
  }
}
#endif
