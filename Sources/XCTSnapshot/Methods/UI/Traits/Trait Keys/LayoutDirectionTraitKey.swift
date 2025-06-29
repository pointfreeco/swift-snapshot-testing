#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit

private struct LayoutDirectionTraitKey: TraitKey {

    static let defaultValue = UITraitEnvironmentLayoutDirection.unspecified

    @available(iOS 17, tvOS 17, *)
    static func apply(
        _ value: Value,
        to traitsOverrides: inout UITraitOverrides
    ) {
        traitsOverrides.layoutDirection = value
    }

    static func apply(_ value: Value, to traitCollection: inout UITraitCollection) {
        #if os(visionOS)
        traitCollection = traitCollection.modifyingTraits {
            $0.layoutDirection = value
        }
        #else
        if #available(iOS 17, tvOS 17, *) {
            traitCollection = traitCollection.modifyingTraits {
                $0.layoutDirection = value
            }
        } else {
            traitCollection = .init(traitsFrom: [
                traitCollection,
                UITraitCollection(layoutDirection: value),
            ])
        }
        #endif
    }
}

extension Traits {

    /// Specifies the layout direction for the UI.
    public var layoutDirection: UITraitEnvironmentLayoutDirection {
        get { self[LayoutDirectionTraitKey.self] }
        set { self[LayoutDirectionTraitKey.self] = newValue }
    }

    /// Creates a `Traits` instance with the specified layout direction.
    public init(layoutDirection: UITraitEnvironmentLayoutDirection) {
        self.init()
        self.layoutDirection = layoutDirection
    }
}
#endif
