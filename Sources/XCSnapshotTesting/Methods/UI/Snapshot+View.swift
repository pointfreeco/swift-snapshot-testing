#if canImport(SwiftUI)
@preconcurrency import SwiftUI

#if os(macOS)
extension AsyncSnapshot where Input: SwiftUI.View & Sendable, Output == ImageBytes {

    /// Default configuration for capturing SwiftUI `View` as image snapshots.
    ///
    /// This configuration provides a basic setup for capturing SwiftUI views with default settings.
    /// It renders the view in its initial state with default sizing and comparison precision.
    ///
    /// - Note: This configuration is suitable for simple views where custom sizing or
    ///   comparison settings are not required.
    public static var image: AsyncSnapshot<Input, Output> {
        .image()
    }

    /// Creates a custom image snapshot configuration for SwiftUI `View`.
    ///
    /// This configuration allows you to capture SwiftUI `View` instances with custom settings for
    /// layout, comparison precision, and other visual traits. It renders the view in isolation,
    /// making it ideal for component testing.
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
    /// struct MyView: View {
    ///     var body: some View {
    ///         Text("Hello, World!")
    ///             .padding()
    ///             .background(Color.blue)
    ///     }
    /// }
    ///
    /// try assert(
    ///     of: MyView(),
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
    }
}
#elseif os(iOS) || os(tvOS) || os(visionOS)
extension Snapshot where Input: SwiftUI.View & Sendable, Output == ImageBytes {

    /// Default configuration for capturing SwiftUI `View` as image snapshots.
    ///
    /// This configuration provides a basic setup for capturing SwiftUI views with default settings.
    /// It renders the view in its initial state with default sizing and comparison precision.
    ///
    /// - Note: This configuration is suitable for simple views where custom sizing or
    ///   comparison settings are not required.
    public static var image: AsyncSnapshot<Input, Output> {
        .image()
    }

    /// Creates a custom image snapshot configuration for SwiftUI `View`.
    ///
    /// This configuration allows you to capture SwiftUI `View` instances with custom settings for
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
    /// Example usage:
    /// ```swift
    /// struct MyView: View {
    ///     var body: some View {
    ///         Text("Hello, World!")
    ///             .padding()
    ///             .background(Color.blue)
    ///     }
    /// }
    ///
    /// try assert(
    ///     of: MyView(),
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
    }
}
#elseif os(watchOS)
@available(watchOS, introduced: 9.0)
extension Snapshot where Input: SwiftUI.View & Sendable, Output == ImageBytes {

    /// Default configuration for capturing SwiftUI `View` as image snapshots on watchOS.
    ///
    /// This configuration provides a basic setup for capturing SwiftUI views with default settings.
    /// It renders the view in its initial state with default sizing and comparison precision.
    ///
    /// - Note: This configuration is suitable for simple watchOS views where custom sizing or
    ///   comparison settings are not required.
    public static var image: AsyncSnapshot<Input, Output> {
        .image()
    }

    /// Creates a custom image snapshot configuration for SwiftUI `View` on watchOS.
    ///
    /// This configuration allows you to capture SwiftUI `View` instances with custom settings for
    /// layout and comparison precision. It renders the view in isolation, making it ideal for component testing.
    ///
    /// - Parameters:
    ///   - precision: Pixel tolerance for comparison (1 = perfect match, lower values allow more variation).
    ///   - scale: The scale factor for the rendered image.
    ///   - layout: Specifies how the view should be sized during rendering.
    ///
    /// Example usage:
    /// ```swift
    /// struct MyWatchView: View {
    ///     var body: some View {
    ///         Text("Hello, watch!")
    ///             .padding()
    ///             .background(Color.green)
    ///     }
    /// }
    ///
    /// try assert(
    ///     of: MyWatchView(),
    ///     as: .image(
    ///         precision: 0.98,
    ///         scale: 2.0
    ///     )
    /// )
    /// ```
    public static func image(
        precision: Float = 1,
        scale: CGFloat = 1,
        layout: SnapshotLayout = .sizeThatFits
    ) -> AsyncSnapshot<Input, Output> {
        let config = LayoutConfiguration.resolve(layout)

        return IdentitySyncSnapshot<ImageBytes>.image(
            precision: precision
        ).map { executor in
            Async(Input.self) { @MainActor view in
                let renderer = ImageRenderer(content: view)
                renderer.scale = scale

                if let size = config.size {
                    renderer.proposedSize = .init(size)
                }

                return try await executor(
                    renderer.uiImage ?? UIImage()
                )
            }
        }
    }
}
#endif
#endif
