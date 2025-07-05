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
                UITraitCollection(accessibilityContrast: value),
            ])
        }
        #endif
    }
}

extension Traits {

    /// Specifies the accessibility contrast setting.
    public var accessibilityContrast: UIAccessibilityContrast {
        get { self[AccessibilityContrastTraitKey.self] }
        set { self[AccessibilityContrastTraitKey.self] = newValue }
    }

    /// Creates a `Traits` instance with the specified accessibility contrast.
    public init(accessibilityContrast: UIAccessibilityContrast) {
        self.init()
        self.accessibilityContrast = accessibilityContrast
    }
}
#endif
