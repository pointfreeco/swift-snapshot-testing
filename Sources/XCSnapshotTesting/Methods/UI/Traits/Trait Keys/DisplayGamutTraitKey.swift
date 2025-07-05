#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit

private struct DisplayGamutTraitKey: TraitKey {

    static let defaultValue = UIDisplayGamut.unspecified

    @available(iOS 17, tvOS 17, *)
    static func apply(
        _ value: Value,
        to traitsOverrides: inout UITraitOverrides
    ) {
        traitsOverrides.displayGamut = value
    }

    static func apply(_ value: Value, to traitCollection: inout UITraitCollection) {
        #if os(visionOS)
        traitCollection = traitCollection.modifyingTraits {
            $0.displayGamut = value
        }
        #else
        if #available(iOS 17, tvOS 17, *) {
            traitCollection = traitCollection.modifyingTraits {
                $0.displayGamut = value
            }
        } else {
            traitCollection = .init(traitsFrom: [
                traitCollection,
                UITraitCollection(displayGamut: value),
            ])
        }
        #endif
    }
}

extension Traits {

    /// Specifies the display gamut (color range) of the screen.
    public var displayGamut: UIDisplayGamut {
        get { self[DisplayGamutTraitKey.self] }
        set { self[DisplayGamutTraitKey.self] = newValue }
    }

    /// Creates a `Traits` instance with the specified display gamut.
    public init(displayGamut: UIDisplayGamut) {
        self.init()
        self.displayGamut = displayGamut
    }
}
#endif
