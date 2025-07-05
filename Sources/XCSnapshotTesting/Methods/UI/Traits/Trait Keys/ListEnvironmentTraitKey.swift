#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit

@available(iOS 18, tvOS 18, *)
private struct ListEnvironmentTraitKey: TraitKey {

    static let defaultValue = UIListEnvironment.unspecified

    static func apply(
        _ value: Value,
        to traitsOverrides: inout UITraitOverrides
    ) {
        traitsOverrides.listEnvironment = value
    }

    static func apply(_ value: Value, to traitCollection: inout UITraitCollection) {
        traitCollection = traitCollection.modifyingTraits {
            $0.listEnvironment = value
        }
    }
}

@available(iOS 18, tvOS 18, *)
extension Traits {

    /// Specifies the list environment characteristics.
    public var listEnvironment: UIListEnvironment {
        get { self[ListEnvironmentTraitKey.self] }
        set { self[ListEnvironmentTraitKey.self] = newValue }
    }

    /// Creates a `Traits` instance with the specified list environment.
    public init(listEnvironment: UIListEnvironment) {
        self.init()
        self.listEnvironment = listEnvironment
    }
}
#endif
