#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

#if os(tvOS) || os(macOS) || os(iOS) || os(visionOS)
extension NSLayoutConstraint {

    func storing(in constraints: inout [NSLayoutConstraint]) -> NSLayoutConstraint {
        constraints.append(self)
        return self
    }
}

extension NSLayoutConstraint {

    static func activate(
        _ constraints: [NSLayoutConstraint],
        storingAt store: inout [NSLayoutConstraint]
    ) {
        activate(constraints)
        store.append(contentsOf: constraints)
    }
}
#endif
