#if os(iOS) || os(visionOS)
import UIKit

private struct UserInterfaceLevelTraitKey: TraitKey {

    static let defaultValue = UIUserInterfaceLevel.unspecified

    @available(iOS 17, tvOS 17, *)
    static func apply(
        _ value: Value,
        to traitsOverrides: inout UITraitOverrides
    ) {
        traitsOverrides.userInterfaceLevel = value
    }

    static func apply(_ value: Value, to traitCollection: inout UITraitCollection) {
        #if os(visionOS)
        traitCollection = traitCollection.modifyingTraits {
            $0.userInterfaceLevel = value
        }
        #else
        if #available(iOS 17, tvOS 17, *) {
            traitCollection = traitCollection.modifyingTraits {
                $0.userInterfaceLevel = value
            }
        } else {
            traitCollection = .init(traitsFrom: [
                traitCollection,
                UITraitCollection(userInterfaceLevel: value),
            ])
        }
        #endif
    }
}

extension Traits {

    /// Specifies the user interface level (e.g., normal, elevated).
    public var userInterfaceLevel: UIUserInterfaceLevel {
        get { self[UserInterfaceLevelTraitKey.self] }
        set { self[UserInterfaceLevelTraitKey.self] = newValue }
    }

    /// Creates a `Traits` instance with the specified user interface level.
    public init(userInterfaceLevel: UIUserInterfaceLevel) {
        self.init()
        self.userInterfaceLevel = userInterfaceLevel
    }
}
#endif
