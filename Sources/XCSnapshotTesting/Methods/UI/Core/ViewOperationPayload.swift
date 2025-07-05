#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
#elseif os(macOS)
@preconcurrency import AppKit
#endif

#if os(iOS) || os(tvOS) || os(macOS) || os(visionOS)
@MainActor
struct ViewOperationPayload {
    let previousRootViewController: SDKViewController?
    let window: SDKWindow
    let input: SnapshotUIController
}

extension Async where Output == SnapshotUIController {

    func connectToWindow(
        _ configuration: SnapshotWindowConfiguration<Input>
    ) -> Async<
        Input, ViewOperationPayload
    > {
        map { @MainActor in
            ViewOperationPayload(
                previousRootViewController: configuration.window.switchRoot($0),
                window: configuration.window,
                input: $0
            )
        }
    }
}

extension Async where Output == ViewOperationPayload {

    func waitLoadingStateIfNeeded(tolerance: TimeInterval) -> Async<Input, Output> {
        map {
            await $0.input.view.waitLoadingStateIfNeeded(tolerance: tolerance)
            return $0
        }
    }

    func layoutIfNeeded() -> Async<Input, Output> {
        map { @MainActor in
            $0.input.layoutIfNeeded()
            return $0
        }
    }

    func snapshot(
        _ executor: Sync<SDKImage, ImageBytes>
    ) -> Async<Input, ImageBytes> {
        map { @MainActor payload in
            let image = try await executor(
                payload.input.snapshot()
            )

            payload.window.removeRootViewController()

            #if os(macOS)
            payload.window.contentViewController = payload.previousRootViewController
            #else
            payload.window.rootViewController = payload.previousRootViewController
            #endif

            payload.input.detachChild()

            if !payload.window.isKeyWindow {
                #if os(macOS)
                payload.window.close()
                #else
                payload.window.isHidden = true
                #endif
            }

            return image
        }
    }

    func descriptor(
        _ executor: Sync<String, StringBytes>,
        method: SnapshotUIController.DescriptorMethod
    ) -> Async<Input, StringBytes> {
        map { @MainActor payload in
            let string = try await executor(
                payload.input.descriptor(method)
            )

            payload.window.removeRootViewController()

            #if os(macOS)
            payload.window.contentViewController = payload.previousRootViewController
            #else
            payload.window.rootViewController = payload.previousRootViewController
            #endif

            payload.input.detachChild()

            if !payload.window.isKeyWindow {
                #if os(macOS)
                payload.window.close()
                #else
                payload.window.isHidden = true
                #endif
            }

            return string
        }
    }
}
#endif
