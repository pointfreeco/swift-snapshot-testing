#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit

@available(iOS 17, tvOS 17, *)
private struct ImageDynamicRangeTraitKey: TraitKey {

    static let defaultValue = UIImage.DynamicRange.unspecified

    static func apply(
        _ value: Value,
        to traitsOverrides: inout UITraitOverrides
    ) {
        traitsOverrides.imageDynamicRange = value
    }

    static func apply(_ value: Value, to traitCollection: inout UITraitCollection) {
        traitCollection = traitCollection.modifyingTraits {
            $0.imageDynamicRange = value
        }
    }
}

@available(iOS 17, tvOS 17, *)
extension Traits {

    /// Specifies the dynamic range of images displayed.
    public var imageDynamicRange: UIImage.DynamicRange {
        get { self[ImageDynamicRangeTraitKey.self] }
        set { self[ImageDynamicRangeTraitKey.self] = newValue }
    }

    /// Creates a `Traits` instance with the specified image dynamic range.
    public init(imageDynamicRange: UIImage.DynamicRange) {
        self.init()
        self.imageDynamicRange = imageDynamicRange
    }
}
#endif
