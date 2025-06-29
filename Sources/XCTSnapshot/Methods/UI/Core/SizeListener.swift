#if canImport(SwiftUI)
import SwiftUI

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(macOS)
@preconcurrency import AppKit
#endif

#if os(iOS) || os(tvOS) || os(macOS) || os(visionOS)
@MainActor
protocol SizeListenerDelegate: AnyObject {

    func viewDidUpdateSize(_ id: ObjectIdentifier, size: CGSize)
}

@MainActor
class SizeListener {

    var id: ObjectIdentifier {
        ObjectIdentifier(self)
    }

    weak var delegate: SizeListenerDelegate? {
        willSet { updateSize(size) }
    }

    private(set) var size: CGSize = .zero
    fileprivate weak var owningView: SDKView?

    init() {}

    fileprivate func updateSize(_ size: CGSize) {
        guard self.size != size else {
            return
        }

        self.size = size
        delegate?.viewDidUpdateSize(id, size: size)
    }

    func dispose() {
        owningView?.removeFromSuperview()
    }
}

// MARK: - UIView Extensions

@MainActor
private class UIViewSizeListener: SDKView {

    let listener: SizeListener

    init(listener: SizeListener) {
        self.listener = listener
        super.init(frame: .zero)
        listener.owningView = self
    }

    required init?(coder: NSCoder) {
        nil
    }

    #if os(macOS)
    override func layout() {
        super.layout()
        guard window != nil, let superview else {
            return
        }

        listener.updateSize(superview.bounds.size)
    }
    #else
    override func layoutSubviews() {
        super.layoutSubviews()
        listener.updateSize(bounds.size)
    }
    #endif
}

@MainActor
extension SDKView {

    func addSizeListener(_ listener: SizeListener) {
        let view = UIViewSizeListener(listener: listener)
        view.translatesAutoresizingMaskIntoConstraints = false
        #if os(macOS)
        addSubview(view, positioned: .below, relativeTo: subviews.first)
        #else
        insertSubview(view, at: .zero)
        #endif
        if #available(macOS 11, *) {
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
                view.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
                view.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            ])
        } else {
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: topAnchor),
                view.bottomAnchor.constraint(equalTo: bottomAnchor),
                view.leadingAnchor.constraint(equalTo: leadingAnchor),
                view.trailingAnchor.constraint(equalTo: trailingAnchor),
            ])
        }
    }
}

// MARK: - SwiftUI Extensions

private struct ViewSizeListener: ViewModifier {

    let listener: SizeListener

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy -> Color in
                    let size = proxy.size

                    Task { @MainActor in
                        listener.updateSize(size)
                    }

                    return Color.black.opacity(.zero)
                }
            )
    }
}

extension View {

    func sizeListener(_ listener: SizeListener) -> some View {
        modifier(ViewSizeListener(listener: listener))
    }
}
#endif
#endif
