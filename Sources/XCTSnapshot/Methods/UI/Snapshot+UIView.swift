#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
#elseif os(macOS)
@preconcurrency import AppKit
#endif

#if os(iOS) || os(tvOS) || os(visionOS)
extension AsyncSnapshot where Input: UIKit.UIView, Output == ImageBytes {

    /// Default configuration for capturing `UIView` as image snapshots.
    ///
    /// This configuration provides a basic setup for capturing views with default settings.
    /// It uses the view's intrinsic content size and default comparison precision.
    ///
    /// - Note: This configuration is suitable for simple views where custom sizing or
    ///   comparison settings are not required.
    public static var image: AsyncSnapshot<Input, Output> {
        .image()
    }

    /// Creates a custom image snapshot configuration for `UIView`.
    ///
    /// This configuration allows you to capture `UIView` instances with custom settings for
    /// layout, comparison precision, and other visual traits. It renders the view in isolation,
    /// making it ideal for component testing.
    ///
    /// - Parameters:
    ///   - sessionRole: Defines the role of the UI session (default is `.windowApplication`).
    ///   - precision: Pixel tolerance for comparison (1 = perfect match, lower values allow more variation).
    ///   - perceptualPrecision: Tolerance for color and tonal differences (values closer to 1 require more exact matches).
    ///   - layout: Specifies how the view should be sized during rendering (e.g., specific device simulation).
    ///   - traits: Collection of UI traits (e.g., accessibility features, display characteristics).
    ///   - delay: Delay before capturing the image (useful for waiting for animations or dynamic content).
    ///   - application: The `UIApplication` instance to render the windows.
    ///
    /// - Example:
    ///   ```swift
    ///   let view = UIView()
    ///   view.backgroundColor = .red
    ///   view.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    ///
    ///   try await assert(
    ///       of: view,
    ///       as: .image(
    ///           layout: .device(.iPhone15Pro),
    ///           precision: 0.98
    ///       )
    ///   )
    ///   ```
    public static func image(
        sessionRole: UISceneSession.Role = .windowApplication,
        precision: Float = 1,
        perceptualPrecision: Float = 1,
        layout: SnapshotLayout = .sizeThatFits,
        traits: Traits = .init(),
        delay: Double = .zero,
        application: UIKit.UIApplication? = nil
    ) -> AsyncSnapshot<Input, Output> {
        let config = LayoutConfiguration.resolve(
            layout,
            with: SnapshotEnvironment.current.traits.merging(traits)
        )

        return IdentitySyncSnapshot.image(
            precision: precision,
            perceptualPrecision: perceptualPrecision
        )
        .withWindow(
            sessionRole: sessionRole,
            application: application,
            operation: { windowConfiguration, executor in
                Async(Input.self) { @MainActor in
                    SnapshotUIController($0, with: config)
                }
                .connectToWindow(windowConfiguration)
                .layoutIfNeeded()
                .sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                #if !os(tvOS)
                .waitLoadingStateIfNeeded(tolerance: SnapshotEnvironment.current.webViewTolerance)
                #endif
                .snapshot(executor)
            }
        )
        .inconsistentTraitsChecker(config.traits)
        .withLock()
    }
}

extension AsyncSnapshot where Input: UIKit.UIView, Output == StringBytes {

    /// A snapshot strategy for comparing views based on a recursive description of their properties
    /// and hierarchies.
    ///
    /// This strategy captures a text-based representation of the view's hierarchy, including property values like frames, opacity, and layer information.
    /// It's useful for verifying the structural integrity of complex views without relying on visual image comparisons.
    ///
    /// Example usage:
    /// ```swift
    /// let view = UIView()
    /// view.backgroundColor = .red
    /// view.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    ///
    /// try await assert(of: view, as: .recursiveDescription)
    /// ```
    ///
    /// Recorded snapshot:
    ///
    /// ```
    /// <UIView; frame = (0 0; 100 100); opaque = NO; layer = <CALayer>>
    /// ```
    public static var recursiveDescription: AsyncSnapshot<Input, Output> {
        Snapshot.recursiveDescription()
    }

    /// Creates a custom snapshot configuration for comparing views based on a recursive description of their properties and hierarchies.
    ///
    /// - Parameters:
    ///   - sessionRole: Defines the role of the UI session (default is `.windowApplication`).
    ///   - layout: Specifies how the view should be sized during rendering.
    ///   - traits: Collection of UI traits (e.g., accessibility features, display characteristics).
    ///   - delay: Delay before capturing the description (useful for waiting for animations or dynamic content).
    ///   - application: The `UIApplication` instance to render the windows.
    ///
    /// Example usage with custom layout:
    /// ```swift
    /// let view = UIView()
    /// view.backgroundColor = .blue
    /// view.frame = CGRect(x: 0, y: 0, width: 200, height: 300)
    ///
    /// try await assert(
    ///     of: view,
    ///     as: .recursiveDescription(
    ///         layout: .fixed(width: 200, height: 300)
    ///     )
    /// )
    /// ```
    public static func recursiveDescription(
        sessionRole: UISceneSession.Role = .windowApplication,
        layout: SnapshotLayout = .sizeThatFits,
        traits: Traits = .init(),
        delay: Double = .zero,
        application: UIKit.UIApplication? = nil
    ) -> AsyncSnapshot<Input, Output> {
        let config = LayoutConfiguration.resolve(
            layout,
            with: SnapshotEnvironment.current.traits.merging(traits)
        )

        return IdentitySyncSnapshot.lines
            .withWindow(
                sessionRole: sessionRole,
                application: application,
                operation: { windowConfiguration, executor in
                    Async(Input.self) { @MainActor in
                        SnapshotUIController($0, with: config)
                    }
                    .connectToWindow(windowConfiguration)
                    .layoutIfNeeded()
                    .sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    #if !os(tvOS)
                    .waitLoadingStateIfNeeded(tolerance: SnapshotEnvironment.current.webViewTolerance)
                    #endif
                    .descriptor(executor, method: .recursiveDescription)
                }
            )
            .withLock()
    }
}
#endif
