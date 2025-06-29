#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit

@available(macCatalyst 16, *)
private struct ToolbarItemPresentationSizeTraitKey: TraitKey {

    static let defaultValue = UINSToolbarItemPresentationSize.unspecified

    @available(iOS 17, tvOS 17, *)
    static func apply(
        _ value: Value,
        to traitsOverrides: inout UITraitOverrides
    ) {
        traitsOverrides.toolbarItemPresentationSize = value
    }

    static func apply(_ value: Value, to traitCollection: inout UITraitCollection) {
        #if os(visionOS)
        traitCollection = traitCollection.modifyingTraits {
            $0.toolbarItemPresentationSize = value
        }
        #else
        if #available(iOS 17, tvOS 17, *) {
            traitCollection = traitCollection.modifyingTraits {
                $0.toolbarItemPresentationSize = value
            }
        } else {
            traitCollection = .init(traitsFrom: [
                traitCollection,
                UITraitCollection(toolbarItemPresentationSize: value),
            ])
        }
        #endif
    }
}

@available(macCatalyst 16, *)
extension Traits {

    /// Specifies the presentation size for toolbar items.
    public var toolbarItemPresentationSize: UINSToolbarItemPresentationSize {
        get { self[ToolbarItemPresentationSizeTraitKey.self] }
        set { self[ToolbarItemPresentationSizeTraitKey.self] = newValue }
    }

    /// Creates a `Traits` instance with the specified toolbar item presentation size.
    public init(toolbarItemPresentationSize: UINSToolbarItemPresentationSize) {
        self.init()
        self.toolbarItemPresentationSize = toolbarItemPresentationSize
    }
}
#endif
