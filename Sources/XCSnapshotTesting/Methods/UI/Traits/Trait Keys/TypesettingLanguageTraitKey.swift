#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit

@available(iOS 17, tvOS 17, *)
private struct TypesettingLanguageTraitKey: TraitKey {

    static let defaultValue: Locale.Language? = nil

    static func apply(
        _ value: Value,
        to traitsOverrides: inout UITraitOverrides
    ) {
        traitsOverrides.typesettingLanguage = value
    }

    static func apply(_ value: Value, to traitCollection: inout UITraitCollection) {
        traitCollection = traitCollection.modifyingTraits {
            $0.typesettingLanguage = value
        }
    }
}

@available(iOS 17, tvOS 17, *)
extension Traits {

    /// Specifies the language used for typesetting.
    public var typesettingLanguage: Locale.Language? {
        get { self[TypesettingLanguageTraitKey.self] }
        set { self[TypesettingLanguageTraitKey.self] = newValue }
    }

    /// Creates a `Traits` instance with the specified typesetting language.
    public init(typesettingLanguage: Locale.Language?) {
        self.init()
        self.typesettingLanguage = typesettingLanguage
    }
}
#endif
