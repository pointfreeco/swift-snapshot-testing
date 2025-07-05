#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit

private struct UserInterfaceIdiomTraitKey: TraitKey {

    static let defaultValue = UIUserInterfaceIdiom.unspecified

    @available(iOS 17, tvOS 17, *)
    static func apply(
        _ value: Value,
        to traitsOverrides: inout UITraitOverrides
    ) {
        traitsOverrides.userInterfaceIdiom = value
    }

    static func apply(_ value: Value, to traitCollection: inout UITraitCollection) {
        #if os(visionOS)
        traitCollection = traitCollection.modifyingTraits {
            $0.userInterfaceIdiom = value
        }
        #else
        if #available(iOS 17, tvOS 17, *) {
            traitCollection = traitCollection.modifyingTraits {
                $0.userInterfaceIdiom = value
            }
        } else {
            traitCollection = .init(traitsFrom: [
                traitCollection,
                UITraitCollection(userInterfaceIdiom: value),
            ])
        }
        #endif
    }
}

extension Traits {

    /// Specifies the user interface idiom (e.g., phone, pad, mac).
    public var userInterfaceIdiom: UIUserInterfaceIdiom {
        get { self[UserInterfaceIdiomTraitKey.self] }
        set { self[UserInterfaceIdiomTraitKey.self] = newValue }
    }

    /// Creates a `Traits` instance with the specified user interface idiom.
    public init(userInterfaceIdiom: UIUserInterfaceIdiom) {
        self.init()
        self.userInterfaceIdiom = userInterfaceIdiom
    }
}
#endif
