#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

#if os(iOS) || os(tvOS) || os(visionOS) || os(macOS)
class SnapshotView: SDKView {

    let configuration: LayoutConfiguration

    private var sizableViews: [ObjectIdentifier: (SDKView, SizeListener)] = [:]

    init(configuration: LayoutConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        #if os(macOS)
        wantsLayer = true
        #endif
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    #if os(macOS)
    override func layout() {
        super.layout()
        self.updateTransformations()
    }
    #else
    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        self.updateTransformations()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateTransformations()
    }
    #endif

    func dispose() {
        defer { sizableViews = [:] }

        for (transformableView, sizeListener) in sizableViews.values {
            sizeListener.dispose()
            transformableView.removeFromSuperview()
        }
    }

    func add(_ view: SDKView, with sizeListener: SizeListener) {
        defer { sizeListener.delegate = self }

        let transformableView = SDKView()
        let containerView = SDKView()

        view.translatesAutoresizingMaskIntoConstraints = false
        transformableView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(view)
        transformableView.addSubview(containerView)

        super.addSubview(transformableView)

        NSLayoutConstraint.activate([
            transformableView.topAnchor.constraint(equalTo: topAnchor),
            transformableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            transformableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            transformableView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: transformableView.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: transformableView.centerYAnchor),
        ])

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: containerView.topAnchor),
            view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
        ])

        sizableViews[sizeListener.id] = (transformableView, sizeListener)
    }

    func calculateContentFrame() -> CGRect {
        var contentSize = sizableViews.values.reduce(CGSize.zero) {
            CGSize(
                width: max($0.width, $1.1.size.width),
                height: max($0.height, $1.1.size.height)
            )
        }

        let safeArea = configuration.safeArea

        contentSize.width += safeArea.left + safeArea.right
        contentSize.height += safeArea.top + safeArea.bottom

        let scale = self.scale(for: contentSize)

        contentSize.width *= scale
        contentSize.height *= scale

        return CGRect(
            x: bounds.midX - contentSize.width / 2,
            y: bounds.midY - contentSize.height / 2,
            width: contentSize.width,
            height: contentSize.height
        )
    }

    private func updateTransformations() {
        for (transformableView, sizeListener) in sizableViews.values {
            downscale(transformableView, with: sizeListener.size)
        }
    }

    private func downscale(_ transformableView: SDKView, with size: CGSize) {
        let safeArea = configuration.safeArea
        let scale = scale(
            for: CGSize(
                width: size.width + safeArea.left + safeArea.right,
                height: size.height + safeArea.top + safeArea.bottom
            )
        )
        #if os(macOS)
        self.layer?.contentsScale = scale
        #else
        transformableView.transform = CGAffineTransform(scaleX: scale, y: scale)
        #endif
        transformableView.recursiveNeedsLayout()
        #if os(macOS)
        needsLayout = true
        #else
        transformableView.layoutIfNeeded()
        #endif
    }

    private func scale(for size: CGSize) -> CGFloat {
        guard frame.size.height > .zero && frame.size.width > .zero else {
            return 1
        }

        let proposedSize: CGSize

        if #available(macOS 11, *) {
            proposedSize = CGSize(
                width: frame.size.width - (safeAreaInsets.left + safeAreaInsets.right),
                height: frame.size.height - (safeAreaInsets.top + safeAreaInsets.bottom)
            )
        } else {
            proposedSize = frame.size
        }

        return proposedSize.scaleThatFits(size)
    }
}

extension SnapshotView: SizeListenerDelegate {

    func viewDidUpdateSize(_ id: ObjectIdentifier, size: CGSize) {
        guard let (transformableView, _) = sizableViews[id] else {
            return
        }

        downscale(transformableView, with: size)
    }
}
#endif
