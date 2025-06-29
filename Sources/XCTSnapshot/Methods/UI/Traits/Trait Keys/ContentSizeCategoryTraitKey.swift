#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit

private struct ContentSizeCategoryTraitKey: TraitKey {

    static let defaultValue = UIContentSizeCategory.unspecified

    @available(iOS 17, tvOS 17, *)
    static func apply(
        _ value: Value,
        to traitsOverrides: inout UITraitOverrides
    ) {
        traitsOverrides.preferredContentSizeCategory = value
    }

    static func apply(_ value: Value, to traitCollection: inout UITraitCollection) {
        #if os(visionOS)
        traitCollection = traitCollection.modifyingTraits {
            $0.preferredContentSizeCategory = value
        }
        #else
        if #available(iOS 17, tvOS 17, *) {
            traitCollection = traitCollection.modifyingTraits {
                $0.preferredContentSizeCategory = value
            }
        } else {
            traitCollection = .init(traitsFrom: [
                traitCollection,
                UITraitCollection(preferredContentSizeCategory: value),
            ])
        }
        #endif
    }
}

extension Traits {

    /// Specifies the preferred content size category for accessibility.
    public var preferredContentSizeCategory: UIContentSizeCategory {
        get { self[ContentSizeCategoryTraitKey.self] }
        set { self[ContentSizeCategoryTraitKey.self] = newValue }
    }

    /// Creates a `Traits` instance with the specified preferred content size category.
    public init(preferredContentSizeCategory: UIContentSizeCategory) {
        self.init()
        self.preferredContentSizeCategory = preferredContentSizeCategory
    }
}
#endif
