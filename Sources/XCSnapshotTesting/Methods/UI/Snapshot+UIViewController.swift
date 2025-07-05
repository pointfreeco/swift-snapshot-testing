#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
#elseif os(macOS)
@preconcurrency import AppKit
#endif

#if os(iOS) || os(tvOS) || os(visionOS)
extension AsyncSnapshot where Input: UIKit.UIViewController, Output == ImageBytes {

    /// Default configuration for capturing `UIViewController` as image snapshots.
    ///
    /// This configuration provides a basic setup for capturing view controllers with default settings.
    /// It renders the view controller's view with default sizing and comparison precision.
    ///
    /// - Note: This configuration is suitable for simple view controllers where custom sizing or
    ///   comparison settings are not required.
    public static var image: AsyncSnapshot<Input, Output> {
        .image()
    }

    /// Creates a custom image snapshot configuration for `UIViewController`.
    ///
    /// This configuration allows you to capture `UIViewController` instances with custom settings for
    /// layout, comparison precision, and other visual traits. It renders the view controller's view
    /// in isolation, making it ideal for screen testing.
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
    /// Example usage:
    /// ```swift
    /// let viewController = UIViewController()
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

extension AsyncSnapshot where Input: UIKit.UIViewController, Output == StringBytes {

    /// A snapshot strategy for comparing view controllers based on their embedded controller hierarchy.
    ///
    /// This strategy captures a text-based representation of the view controller hierarchy, including states like "appeared" or "disappeared."
    /// It's useful for verifying the structural integrity of complex view controller hierarchies without relying on visual image comparisons.
    ///
    /// Example usage:
    /// ```swift
    /// let tabBarController = UITabBarController()
    /// tabBarController.viewControllers = [UIViewController(), UIViewController()]
    ///
    /// try await assert(of: tabBarController, as: .hierarchy)
    /// ```
    ///
    /// Recorded snapshot:
    ///
    /// ```
    /// <UITabBarController>, state: appeared, view: <UILayoutContainerView>
    ///    | <UINavigationController>, state: appeared, view: <UILayoutContainerView>
    ///    |    | <UIViewController>, state: appeared, view: <UIView>
    ///    | <UINavigationController>, state: disappeared, view: <UILayoutContainerView> not in the window
    ///    |    | <UIViewController>, state: disappeared, view: (view not loaded)
    /// ```
    public static var hierarchy: AsyncSnapshot<Input, Output> {
        Snapshot.hierarchy()
    }

    /// A snapshot strategy for comparing view controller views based on a recursive description of their properties and hierarchies.
    ///
    /// This strategy captures a text-based representation of the view hierarchy, including property values like frames, opacity, and layer information.
    /// It's useful for verifying the structural integrity of complex views within view controllers without relying on visual image comparisons.
    ///
    /// Example usage:
    /// ```swift
    /// let viewController = UIViewController()
    /// viewController.view.backgroundColor = .red
    /// viewController.view.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    ///
    /// try await assert(of: viewController, as: .recursiveDescription)
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

    /// Creates a custom snapshot configuration for comparing view controllers based on their embedded controller hierarchy.
    ///
    /// - Parameters:
    ///   - sessionRole: Defines the role of the UI session (default is `.windowApplication`).
    ///   - layout: Specifies how the view should be sized during rendering.
    ///   - traits: Collection of UI traits (e.g., accessibility features, display characteristics).
    ///   - delay: Delay before capturing the hierarchy description (useful for waiting for animations or dynamic content).
    ///   - application: The `UIApplication` instance to render the windows.
    ///
    /// Example usage with custom layout:
    /// ```swift
    /// let viewController = UIViewController()
    /// viewController.view.backgroundColor = .blue
    /// viewController.view.frame = CGRect(x: 0, y: 0, width: 200, height: 300)
    ///
    /// try await assert(
    ///     of: viewController,
    ///     as: .hierarchy(
    ///         layout: .fixed(width: 200, height: 300)
    ///     )
    /// )
    /// ```
    public static func hierarchy(
        sessionRole: UISceneSession.Role = .windowApplication,
        layout: SnapshotLayout = .sizeThatFits,
        traits: Traits = .init(),
        delay: Double = .zero,
        application: UIKit.UIApplication? = nil
    ) -> AsyncSnapshot<Input, Output> {
        descriptor(
            method: .hierarchy,
            sessionRole: sessionRole,
            layout: layout,
            traits: traits,
            delay: delay,
            application: application
        )
    }

    /// Creates a custom snapshot configuration for comparing view controller views based on a recursive description of their properties and hierarchies.
    ///
    /// - Parameters:
    ///   - sessionRole: Defines the role of the UI session (default is `.windowApplication`).
    ///   - layout: Specifies how the view should be sized during rendering.
    ///   - traits: Collection of UI traits (e.g., accessibility features, display characteristics).
    ///   - delay: Delay before capturing the recursive description (useful for waiting for animations or dynamic content).
    ///   - application: The `UIApplication` instance to render the windows.
    ///
    /// Example usage with custom layout:
    /// ```swift
    /// let viewController = UIViewController()
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
        sessionRole: UISceneSession.Role = .windowApplication,
        layout: SnapshotLayout = .sizeThatFits,
        traits: Traits = .init(),
        delay: Double = .zero,
        application: UIKit.UIApplication? = nil
    ) -> AsyncSnapshot<Input, Output> {
        descriptor(
            method: .recursiveDescription,
            sessionRole: sessionRole,
            layout: layout,
            traits: traits,
            delay: delay,
            application: application
        )
    }

    private static func descriptor(
        method: SnapshotUIController.DescriptorMethod,
        sessionRole: UISceneSession.Role,
        layout: SnapshotLayout,
        traits: Traits,
        delay: Double,
        application: UIKit.UIApplication?
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
                    .descriptor(executor, method: method)
                }
            )
            .withLock()
    }
}
#endif
