#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit

private struct LegibilityWeightTraitKey: TraitKey {

    static let defaultValue = UILegibilityWeight.unspecified

    @available(iOS 17, tvOS 17, *)
    static func apply(
        _ value: Value,
        to traitsOverrides: inout UITraitOverrides
    ) {
        traitsOverrides.legibilityWeight = value
    }

    static func apply(_ value: Value, to traitCollection: inout UITraitCollection) {
        #if os(visionOS)
        traitCollection = traitCollection.modifyingTraits {
            $0.legibilityWeight = value
        }
        #else
        if #available(iOS 17, tvOS 17, *) {
            traitCollection = traitCollection.modifyingTraits {
                $0.legibilityWeight = value
            }
        } else {
            traitCollection = .init(traitsFrom: [
                traitCollection,
                UITraitCollection(legibilityWeight: value),
            ])
        }
        #endif
    }
}

extension Traits {

    /// Specifies the legibility weight for text.
    public var legibilityWeight: UILegibilityWeight {
        get { self[LegibilityWeightTraitKey.self] }
        set { self[LegibilityWeightTraitKey.self] = newValue }
    }

    /// Creates a `Traits` instance with the specified legibility weight.
    public init(legibilityWeight: UILegibilityWeight) {
        self.init()
        self.legibilityWeight = legibilityWeight
    }
}
#endif
