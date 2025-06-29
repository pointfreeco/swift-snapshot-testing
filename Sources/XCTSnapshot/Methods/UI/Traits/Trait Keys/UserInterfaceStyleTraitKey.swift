#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit

private struct UserInterfaceStyleTraitKey: TraitKey {

    static let defaultValue = UIUserInterfaceStyle.unspecified

    @available(iOS 17, tvOS 17, *)
    static func apply(
        _ value: Value,
        to traitsOverrides: inout UITraitOverrides
    ) {
        traitsOverrides.userInterfaceStyle = value
    }

    static func apply(_ value: Value, to traitCollection: inout UITraitCollection) {
        #if os(visionOS)
        traitCollection = traitCollection.modifyingTraits {
            $0.userInterfaceStyle = value
        }
        #else
        if #available(iOS 17, tvOS 17, *) {
            traitCollection = traitCollection.modifyingTraits {
                $0.userInterfaceStyle = value
            }
        } else {
            traitCollection = .init(traitsFrom: [
                traitCollection,
                UITraitCollection(userInterfaceStyle: value),
            ])
        }
        #endif
    }
}

extension Traits {

    /// Specifies the user interface style (light, dark).
    public var userInterfaceStyle: UIUserInterfaceStyle {
        get { self[UserInterfaceStyleTraitKey.self] }
        set { self[UserInterfaceStyleTraitKey.self] = newValue }
    }

    /// Creates a `Traits` instance with the specified user interface style.
    public init(userInterfaceStyle: UIUserInterfaceStyle) {
        self.init()
        self.userInterfaceStyle = userInterfaceStyle
    }
}
#endif
