#if os(macOS)
import AppKit
#elseif os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#endif

#if os(macOS) || os(iOS) || os(visionOS)
import WebKit
#endif

#if os(iOS) || os(tvOS) || os(macOS) || os(visionOS)

@MainActor
extension SDKView {

    func asImage() -> SDKImage {
        #if os(macOS)
        guard let rep = bitmapImageRepForCachingDisplay(in: bounds) else {
            return SDKImage()
        }

        cacheDisplay(in: bounds, to: rep)

        let image = SDKImage(size: bounds.size)
        image.addRepresentation(rep)

        return image
        #else
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
        #endif
    }

    func withController() -> SDKViewController {
        UIViewHostingController(self)
    }

    func waitLoadingStateIfNeeded(tolerance: TimeInterval) async {
        #if os(iOS) || os(macOS) || os(visionOS)
        if let webView = self as? WKWebView {
            try? await webView.waitLoadingState(tolerance: tolerance)
            return
        }

        for subview in subviews {
            await subview.waitLoadingStateIfNeeded(tolerance: tolerance)
        }
        #endif
    }

    func recursiveNeedsLayout() {
        guard window != nil else {
            return
        }

        invalidateIntrinsicContentSize()
        #if os(macOS)
        needsUpdateConstraints = true
        needsLayout = true
        #else
        setNeedsUpdateConstraints()
        setNeedsLayout()
        #endif

        switch self {
        #if os(macOS)
        #else
        case is UITableView, is UICollectionView:
            break
        #endif
        default:
            for view in subviews {
                view.recursiveNeedsLayout()
            }
        }
    }
}

@MainActor
private class UIViewHostingController: SDKViewController {

    private let contentView: SDKView

    init(_ contentView: SDKView) {
        self.contentView = contentView
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        view = contentView
    }
}

@MainActor
private var kUIViewLock = 0

@MainActor
extension SDKView {

    private var lock: AsyncLock {
        if let lock = objc_getAssociatedObject(self, &kUIViewLock) as? AsyncLock {
            return lock
        }

        let lock = AsyncLock()
        objc_setAssociatedObject(self, &kUIViewLock, lock, .OBJC_ASSOCIATION_RETAIN)
        return lock
    }

    fileprivate func withLock<Value: Sendable>(
        _ body: @Sendable () async throws -> Value
    ) async throws -> Value {
        try await lock.withLock(body)
    }
}

extension Snapshot {

    func withLock<Input: SDKView, Output: BytesRepresentable>() -> AsyncSnapshot<Input, Output>
    where Executor == Async<Input, Output> {
        map { executor in
            Async(Input.self) { view in
                try await view.withLock {
                    try await executor(view)
                }
            }
        }
    }
}
#endif

#if os(iOS) || os(tvOS) || os(visionOS)
@MainActor
private var kUIViewTraits = 0

extension SDKView {

    private var traits: Traits? {
        get { objc_getAssociatedObject(self, &kUIViewTraits) as? Traits }
        set {
            objc_setAssociatedObject(
                self,
                &kUIViewTraits,
                newValue,
                .OBJC_ASSOCIATION_RETAIN
            )
        }
    }

    func inconsistentTraitsChecker(for traits: Traits) {
        defer { self.traits = traits }
        self.traits?.inconsistentTraitsChecker(self, to: traits)
    }
}

extension Snapshot {

    func inconsistentTraitsChecker<Input: SDKView, Output: BytesRepresentable>(
        _ traits: Traits
    ) -> AsyncSnapshot<Input, Output> where Executor == Async<Input, Output> {
        map { executor in
            Async(Input.self) { @MainActor in
                $0.inconsistentTraitsChecker(for: traits)
                return try await executor($0)
            }
        }
    }
}
#endif
