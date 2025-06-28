#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit

private struct ForceTouchCapabilityTraitKey: TraitKey {

    static let defaultValue = UIForceTouchCapability.unknown

    @available(iOS 17, tvOS 17, *)
    static func apply(
        _ value: Value,
        to traitsOverrides: inout UITraitOverrides
    ) {
        traitsOverrides.forceTouchCapability = value
    }

    static func apply(_ value: Value, to traitCollection: inout UITraitCollection) {
        #if os(visionOS)
        traitCollection = traitCollection.modifyingTraits {
            $0.forceTouchCapability = value
        }
        #else
        if #available(iOS 17, tvOS 17, *) {
            traitCollection = traitCollection.modifyingTraits {
                $0.forceTouchCapability = value
            }
        } else {
            traitCollection = .init(traitsFrom: [
                traitCollection,
                UITraitCollection(forceTouchCapability: value),
            ])
        }
        #endif
    }
}

extension Traits {

    /// Specifies the force touch capability of the device.
    public var forceTouchCapability: UIForceTouchCapability {
        get { self[ForceTouchCapabilityTraitKey.self] }
        set { self[ForceTouchCapabilityTraitKey.self] = newValue }
    }

    /// Creates a `Traits` instance with the specified force touch capability.
    public init(forceTouchCapability: UIForceTouchCapability) {
        self.init()
        self.forceTouchCapability = forceTouchCapability
    }
}
#endif
