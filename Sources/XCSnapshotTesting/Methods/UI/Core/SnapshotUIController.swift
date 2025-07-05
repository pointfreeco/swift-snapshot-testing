#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
import SwiftUI
import SceneKit
import SpriteKit
#elseif os(macOS)
@preconcurrency import AppKit
import SwiftUI
import SceneKit
import SpriteKit
#endif

#if os(iOS) || os(tvOS) || os(macOS) || os(visionOS)
@MainActor
class SnapshotUIController: SDKViewController {

    // MARK: - Internal properties

    #if os(iOS) || os(tvOS) || os(visionOS)
    override var shouldAutomaticallyForwardAppearanceMethods: Bool {
        true
    }
    #endif

    var configuration: LayoutConfiguration {
        snapshotView.configuration
    }

    private let snapshotView: SnapshotView

    // MARK: - Private properties

    private var childConstraints = [NSLayoutConstraint]()
    private let childController: SDKViewController
    private let childSizeListener: SizeListener

    private var isWaitingSnapshotSignal = false
    private let snapshotSignal = AsyncSignal()

    // MARK: - Inits

    init(_ view: SDKView, with configuration: LayoutConfiguration) {
        let sizeListener = SizeListener()
        view.addSizeListener(sizeListener)
        self.childController = view.withController()
        self.childSizeListener = sizeListener
        self.snapshotView = .init(configuration: configuration)
        super.init(nibName: nil, bundle: nil)
    }

    init(_ viewController: SDKViewController, with configuration: LayoutConfiguration) {
        let sizeListener = SizeListener()
        viewController.view.addSizeListener(sizeListener)
        self.childController = viewController
        self.childSizeListener = sizeListener
        self.snapshotView = .init(configuration: configuration)
        super.init(nibName: nil, bundle: nil)
    }

    init<Content: View>(_ content: Content, with configuration: LayoutConfiguration) {
        func size(_ keyPath: KeyPath<CGSize, CGFloat>) -> CGFloat? {
            guard let size = configuration.size else {
                return nil
            }

            let value = size[keyPath: keyPath]
            return value == .zero ? nil : value
        }

        let sizeListener = SizeListener()
        let rootView =
            content
            .frame(width: size(\.width), height: size(\.height))
            .sizeListener(sizeListener)
        #if os(macOS)
        let viewController = NSHostingController(rootView: rootView)
        #else
        let viewController = UIHostingController(rootView: rootView)
        #endif
        self.childController = viewController
        self.childSizeListener = sizeListener
        self.snapshotView = .init(configuration: configuration)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - Super methods

    override func loadView() {
        view = snapshotView
        snapshotView.translatesAutoresizingMaskIntoConstraints = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        attachChild()
        #if !os(macOS)
        configuration.traits.commit(in: self)
        #endif
    }

    #if os(macOS)
    override func viewDidLayout() {
        super.viewDidLayout()
        if isWaitingSnapshotSignal {
            isWaitingSnapshotSignal = false

            Task {
                await snapshotSignal.signal()
            }
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        let trackingArea = NSTrackingArea(
            rect: view.bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow],
            owner: view
        )

        view.addTrackingArea(trackingArea)
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()

        for trackingArea in view.trackingAreas {
            view.removeTrackingArea(trackingArea)
        }
    }
    #else
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if isWaitingSnapshotSignal {
            isWaitingSnapshotSignal = false

            Task {
                await snapshotSignal.signal()
            }
        }
    }
    #if os(iOS)
    override func shouldAutomaticallyForwardRotationMethods() -> Bool {
        true
    }
    #endif
    #endif

    // MARK: - Internal methods

    func layoutIfNeeded() {
        #if os(macOS)
        let view = childController.view
        #else
        let view: UIView = childController.view ?? view
        #endif

        let size = view.frame.size
        if size.height == .zero || size.width == .zero {
            #if os(macOS)
            view.needsLayout = true
            view.layoutSubtreeIfNeeded()
            #else
            view.setNeedsLayout()
            view.layoutIfNeeded()
            #endif
        }
    }

    func snapshot() async throws -> SDKImage {
        #if !os(macOS)
        let traits = configuration.traits
        #endif

        isWaitingSnapshotSignal = true

        #if os(macOS)
        childController.view.needsLayout = true
        view.needsLayout = true
        view.layoutSubtreeIfNeeded()
        #else
        view.recursiveNeedsLayout()
        view.layoutIfNeeded()
        #endif

        try await snapshotSignal.wait()
        await snapshotSignal.lock()

        if let sceneView = childController.view as? SCNView {
            return sceneView.snapshot()
        }

        if let skView = childController.view as? SKView,
            let scene = skView.scene,
            let image = skView.texture(from: scene)?.cgImage()
        {
            #if os(macOS)
            return .init(
                cgImage: image,
                size: CGSize(
                    width: image.width,
                    height: image.height
                )
            )
            #else
            return .init(cgImage: image)
            #endif
        }

        #if os(macOS)
        return try snapshot(view)
        #else
        return try snapshot(view, with: traits)
        #endif
    }

    enum DescriptorMethod: String {
        #if os(macOS)
        case subtreeDescription = "_subtreeDescription"
        #else
        case hierarchy = "_printHierarchy"
        case recursiveDescription = "recursiveDescription"
        #endif

        @MainActor
        fileprivate func callAsFunction(_ viewController: SDKViewController) -> String {
            let reference: NSObject

            switch self {
            #if os(macOS)
            case .subtreeDescription:
                reference = viewController.view
            #else
            case .hierarchy:
                reference = viewController
            case .recursiveDescription:
                reference = viewController.view
            #endif
            }

            return
                (reference
                .perform(Selector(rawValue))
                .retain()
                .takeUnretainedValue() as! String).sanitizingPointersReferences()
        }
    }

    func descriptor(_ method: DescriptorMethod) async throws -> String {
        isWaitingSnapshotSignal = true

        #if os(macOS)
        childController.view.needsLayout = true
        view.needsLayout = true
        view.layoutSubtreeIfNeeded()
        #else
        childController.view.setNeedsLayout()
        view.setNeedsLayout()
        view.layoutIfNeeded()
        #endif

        try await snapshotSignal.wait()
        await snapshotSignal.lock()

        return method(childController)
    }

    func detachChild() {
        defer { snapshotView.dispose() }

        NSLayoutConstraint.deactivate(childConstraints)
        #if !os(macOS)
        childController.additionalSafeAreaInsets = .zero
        #endif

        #if !os(macOS)
        childController.willMove(toParent: nil)
        #endif
        childController.view.removeFromSuperview()
        childController.removeFromParent()
    }

    // MARK: - Private methods

    private func attachChild() {
        addChild(childController)
        snapshotView.add(childController.view, with: childSizeListener)
        #if !os(macOS)
        childController.didMove(toParent: self)
        #endif

        let heightAnchor = childController.view.heightAnchor.constraint(
            equalTo: view.heightAnchor,
            multiplier: 1
        )

        let widthAnchor = childController.view.widthAnchor.constraint(
            equalTo: view.widthAnchor,
            multiplier: 1
        )

        #if os(macOS)
        heightAnchor.priority = .fittingSizeCompression
        widthAnchor.priority = .fittingSizeCompression
        #else
        heightAnchor.priority = .fittingSizeLevel
        widthAnchor.priority = .fittingSizeLevel
        #endif

        NSLayoutConstraint.activate(
            [
                heightAnchor,
                widthAnchor,
            ],
            storingAt: &childConstraints
        )

        setupSizeConstraints()

        #if !os(macOS)
        childController.additionalSafeAreaInsets = configuration.safeArea
        #endif
    }

    private func setupSizeConstraints() {
        let size = configuration.size ?? .zero

        if size.height > .zero {
            childController.view.setContentHuggingPriority(.defaultLow, for: .vertical)
            childController.view.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

            let heightAnchor = childController.view.heightAnchor.constraint(
                equalToConstant: size.height
            )

            heightAnchor.priority = .required

            NSLayoutConstraint.activate(
                [
                    heightAnchor
                ],
                storingAt: &childConstraints
            )
        } else {
            childController.view.setContentHuggingPriority(.required, for: .vertical)
            childController.view.setContentCompressionResistancePriority(.required, for: .vertical)
        }

        if size.width > .zero {
            childController.view.setContentHuggingPriority(.defaultLow, for: .horizontal)
            childController.view.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

            let widthAnchor = childController.view.widthAnchor.constraint(
                equalToConstant: size.width
            )

            widthAnchor.priority = .required

            NSLayoutConstraint.activate(
                [
                    widthAnchor
                ],
                storingAt: &childConstraints
            )
        } else {
            childController.view.setContentHuggingPriority(.required, for: .horizontal)
            childController.view.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
    }

    #if os(macOS)
    private func snapshot(_ view: SDKView) throws -> SDKImage {
        let bounds = snapshotView.calculateContentFrame()
        guard let rep = view.bitmapImageRepForCachingDisplay(in: bounds) else {
            throw RenderingError()
        }

        view.cacheDisplay(in: bounds, to: rep)

        let snapshot = NSImage(size: rep.size)
        snapshot.addRepresentation(rep)
        return snapshot
    }
    #else
    private func snapshot(
        _ view: SDKView,
        with traits: Traits
    ) throws -> SDKImage {
        let bounds = snapshotView.calculateContentFrame()

        let format = UIGraphicsImageRendererFormat(
            for: traits()
        )

        #if os(visionOS)
        format.scale = traits.displayScale
        #else
        format.scale = view.window?.screen.scale ?? traits.displayScale
        #endif

        let renderer = UIGraphicsImageRenderer(
            bounds: bounds,
            format: format
        )

        return renderer.image {
            view.layer.render(in: $0.cgContext)
        }
    }
    #endif
}
#endif

#if os(macOS)
import CoreGraphics
func CGContextCreateBitmapContext(size: CGSize, opaque: Bool, scale: CGFloat) -> CGContext? {
    var scale = scale

    if scale == .zero {
        // Match `UIGraphicsBeginImageContextWithOptions`, reset to the scale factor of the device’s main screen if scale is 0.
        scale = NSScreen.main?.backingScaleFactor ?? 1
    }

    let width = ceil(size.width * scale)
    let height = ceil(size.height * scale)

    guard width >= 1, height >= 1 else {
        return nil
    }

    guard let space = NSScreen.main?.colorSpace?.cgColorSpace else {
        return nil
    }
    // kCGImageAlphaNone is not supported in CGBitmapContextCreate.
    // Check #3330 for more detail about why this bitmap is choosen.
    // From v5.17.0, use runtime detection of bitmap info instead of hardcode.
    // However, macOS's runtime detection will also call this function, cause recursive, so still hardcode here
    let bitmapInfo: CGBitmapInfo
    if !opaque {
        // [NSImage imageWithSize:flipped:drawingHandler:] returns float(16-bits) RGBA8888 on alpha image, which we don't need
        bitmapInfo = [
            .byteOrderDefault, .init(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
        ]
    } else {
        bitmapInfo = [.byteOrderDefault, .init(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)]
    }

    guard
        let context = CGContext(
            data: nil,
            width: Int(width),
            height: Int(height),
            bitsPerComponent: 8,
            bytesPerRow: .zero,
            space: space,
            bitmapInfo: bitmapInfo.rawValue
        )
    else { return nil }

    context.scaleBy(x: scale, y: scale)

    return context
}

struct RenderingError: Error {}
#endif
