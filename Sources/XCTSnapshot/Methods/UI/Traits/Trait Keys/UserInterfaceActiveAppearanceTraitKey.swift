#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit

@available(iOS 14, tvOS 14, *)
private struct UserInterfaceActiveAppearanceTraitKey: TraitKey {

    static let defaultValue = UIUserInterfaceActiveAppearance.unspecified

    @available(iOS 17, tvOS 17, *)
    static func apply(
        _ value: Value,
        to traitsOverrides: inout UITraitOverrides
    ) {
        traitsOverrides.activeAppearance = value
    }

    static func apply(_ value: Value, to traitCollection: inout UITraitCollection) {
        #if os(visionOS)
        traitCollection = traitCollection.modifyingTraits {
            $0.activeAppearance = value
        }
        #else
        if #available(iOS 17, tvOS 17, *) {
            traitCollection = traitCollection.modifyingTraits {
                $0.activeAppearance = value
            }
        } else {
            traitCollection = .init(traitsFrom: [
                traitCollection,
                UITraitCollection(activeAppearance: value),
            ])
        }
        #endif
    }
}

@available(iOS 14, tvOS 14, *)
extension Traits {

    /// Specifies the active appearance of the interface.
    public var activeAppearance: UIUserInterfaceActiveAppearance {
        get { self[UserInterfaceActiveAppearanceTraitKey.self] }
        set { self[UserInterfaceActiveAppearanceTraitKey.self] = newValue }
    }

    /// Creates a `Traits` instance with the specified active appearance.
    public init(activeAppearance: UIUserInterfaceActiveAppearance) {
        self.init()
        self.activeAppearance = activeAppearance
    }
}
#endif
