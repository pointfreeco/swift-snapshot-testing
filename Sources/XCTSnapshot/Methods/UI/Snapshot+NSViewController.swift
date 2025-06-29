#if os(macOS)
import AppKit
import Cocoa

extension AsyncSnapshot where Input: NSViewController & Sendable, Output == ImageBytes {

    /// Default configuration for capturing `NSViewController` as image snapshots.
    ///
    /// This configuration provides a basic setup for capturing view controllers with default settings.
    /// It renders the view controller's view with default sizing and comparison precision.
    ///
    /// - Note: This configuration is suitable for simple view controllers where custom sizing or
    ///   comparison settings are not required.
    public static var image: AsyncSnapshot<Input, Output> {
        .image()
    }

    /// Creates a custom image snapshot configuration for `NSViewController`.
    ///
    /// This configuration allows you to capture `NSViewController` instances with custom settings for
    /// layout, comparison precision, and other visual traits. It renders the view controller's view
    /// in isolation, making it ideal for screen testing.
    ///
    /// - Parameters:
    ///   - precision: Pixel tolerance for comparison (1 = perfect match, lower values allow more variation).
    ///   - perceptualPrecision: Tolerance for color and tonal differences (values closer to 1 require more exact matches).
    ///   - layout: Specifies how the view should be sized during rendering (e.g., specific device simulation).
    ///   - delay: Delay before capturing the image (useful for waiting for animations or dynamic content).
    ///   - application: The `NSApplication` instance to render the windows.
    ///
    /// Example usage:
    /// ```swift
    /// let viewController = NSViewController()
    /// viewController.view.backgroundColor = .red
    /// viewController.view.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    ///
    /// try await assert(
    ///     of: viewController,
    ///     as: .image(
    ///         layout: .device(.iPhone15Pro),
    ///         precision: 0.98
    ///     )
    /// )
    /// ```
    public static func image(
        precision: Float = 1,
        perceptualPrecision: Float = 1,
        layout: SnapshotLayout = .sizeThatFits,
        delay: Double = .zero,
        application: NSApplication? = nil
    ) -> AsyncSnapshot<Input, Output> {
        let config = LayoutConfiguration.resolve(layout)

        return IdentitySyncSnapshot.image(
            precision: precision,
            perceptualPrecision: perceptualPrecision
        )
        .withWindow(
            sessionRole: .windowApplication,
            application: application,
            operation: { windowConfiguration, executor in
                Async(Input.self) { @MainActor in
                    SnapshotUIController($0, with: config)
                }
                .connectToWindow(windowConfiguration)
                .layoutIfNeeded()
                .sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                .waitLoadingStateIfNeeded(tolerance: SnapshotEnvironment.current.webViewTolerance)
                .snapshot(executor)
            }
        )
        #if !os(macOS)
        .inconsistentTraitsChecker(config.traits)
        #endif
        .withLock()
    }
}

extension Snapshot where Input: NSViewController, Output == StringBytes {

    /// A snapshot strategy for comparing view controller views based on a recursive description of their properties and hierarchies.
    ///
    /// This strategy captures a text-based representation of the view hierarchy, including property values like frames, opacity, and layer information.
    /// It's useful for verifying the structural integrity of complex views within view controllers without relying on visual image comparisons.
    ///
    /// Example usage:
    /// ```swift
    /// let viewController = NSViewController()
    /// viewController.view.backgroundColor = .red
    /// viewController.view.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    ///
    /// try await assert(of: viewController, as: .recursiveDescription)
    /// ```
    ///
    /// Recorded snapshot:
    ///
    /// ```
    /// <NSView; frame = (0 0; 100 100); opaque = NO; layer = <CALayer>>
    /// ```
    public static var recursiveDescription: AsyncSnapshot<Input, Output> {
        .recursiveDescription()
    }

    /// Creates a custom snapshot configuration for comparing view controller views based on a recursive description of their properties and hierarchies.
    ///
    /// - Parameters:
    ///   - layout: Specifies how the view should be sized during rendering.
    ///   - delay: Delay before capturing the recursive description (useful for waiting for animations or dynamic content).
    ///   - application: The `NSApplication` instance to render the windows.
    ///
    /// Example usage with custom layout:
    /// ```swift
    /// let viewController = NSViewController()
    /// viewController.view.backgroundColor = .green
    /// viewController.view.frame = CGRect(x: 0, y: 0, width: 300, height: 400)
    ///
    /// try await assert(
    ///     of: viewController,
    ///     as: .recursiveDescription(
    ///         layout: .fixed(width: 300, height: 400)
    ///     )
    /// )
    /// ```
    public static func recursiveDescription(
        layout: SnapshotLayout = .sizeThatFits,
        delay: Double = .zero,
        application: NSApplication? = nil
    ) -> AsyncSnapshot<Input, Output> {
        let config = LayoutConfiguration.resolve(layout)

        return IdentitySyncSnapshot.lines
            .withWindow(
                sessionRole: .windowApplication,
                application: application,
                operation: { windowConfiguration, executor in
                    Async(Input.self) { @MainActor in
                        SnapshotUIController($0, with: config)
                    }
                    .connectToWindow(windowConfiguration)
                    .layoutIfNeeded()
                    .sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    .waitLoadingStateIfNeeded(tolerance: SnapshotEnvironment.current.webViewTolerance)
                    .descriptor(executor, method: .subtreeDescription)
                }
            )
            #if !os(macOS)
        .inconsistentTraitsChecker(config.traits)
        #endif
        .withLock()
    }
}
#endif
