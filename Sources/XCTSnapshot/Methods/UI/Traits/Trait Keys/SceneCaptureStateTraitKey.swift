#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit

@available(iOS 17, tvOS 17, *)
private struct SceneCaptureStateTraitKey: TraitKey {

    static let defaultValue = UISceneCaptureState.unspecified

    static func apply(
        _ value: Value,
        to traitsOverrides: inout UITraitOverrides
    ) {
        traitsOverrides.sceneCaptureState = value
    }

    static func apply(_ value: Value, to traitCollection: inout UITraitCollection) {
        traitCollection = traitCollection.modifyingTraits {
            $0.sceneCaptureState = value
        }
    }
}

@available(iOS 17, tvOS 17, *)
extension Traits {

    /// Specifies the scene capture state.
    public var sceneCaptureState: UISceneCaptureState {
        get { self[SceneCaptureStateTraitKey.self] }
        set { self[SceneCaptureStateTraitKey.self] = newValue }
    }

    /// Creates a `Traits` instance with the specified scene capture state.
    public init(sceneCaptureState: UISceneCaptureState) {
        self.init()
        self.sceneCaptureState = sceneCaptureState
    }
}
#endif
