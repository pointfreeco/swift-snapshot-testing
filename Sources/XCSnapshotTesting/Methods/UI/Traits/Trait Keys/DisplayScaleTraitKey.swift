#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit

private struct DisplayScaleTraitKey: TraitKey {

    static let defaultValue: CGFloat = 1

    @available(iOS 17, tvOS 17, *)
    static func apply(
        _ value: Value,
        to traitsOverrides: inout UITraitOverrides
    ) {
        traitsOverrides.displayScale = value
    }

    static func apply(_ value: Value, to traitCollection: inout UITraitCollection) {
        #if os(visionOS)
        traitCollection = traitCollection.modifyingTraits {
            $0.displayScale = value
        }
        #else
        if #available(iOS 17, tvOS 17, *) {
            traitCollection = traitCollection.modifyingTraits {
                $0.displayScale = value
            }
        } else {
            traitCollection = .init(traitsFrom: [
                traitCollection,
                UITraitCollection(displayScale: value),
            ])
        }
        #endif
    }
}

extension Traits {

    /// Specifies the display scale (screen resolution) of the device.
    public var displayScale: CGFloat {
        get { self[DisplayScaleTraitKey.self] }
        set { self[DisplayScaleTraitKey.self] = newValue }
    }

    /// Creates a `Traits` instance with the specified display scale.
    public init(displayScale: CGFloat) {
        self.init()
        self.displayScale = displayScale
    }
}
#endif
