#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
#elseif os(macOS)
@preconcurrency import AppKit
#endif

#if os(iOS) || os(tvOS) || os(visionOS)
extension Snapshot where Input: UIKit.UIApplication, Output == ImageBytes {

    /// Default configuration for capturing `UIApplication` as image snapshots.
    ///
    /// This configuration is particularly useful when used with any UI testing framework to capture the current UI state after performing user interactions.
    /// It allows you to drive UI interactions using the UI testing framework functions and take snapshots of the rendered UI at strategic moments.
    ///
    /// Notes:
    ///   - Uses default values for precision (`precision: 1`) and other parameters.
    ///   - Captures the current screen rendered in `UIWindow`.
    ///   - Useful for end-to-end testing where you need to verify the visual state after a series of actions.
    ///
    /// Example usage with XCUITest (renamed on Xcode 16.3 as XCUIAutomation):
    /// ```swift
    /// let app = XCUIApplication()
    /// app.launch()
    ///
    /// // Perform UI interactions
    /// app.buttons["Login"].tap()
    ///
    /// // Capture snapshot of the current UI state
    /// try assert(of: UIApplication.shared, as: .image)
    /// ```
    public static var image: AsyncSnapshot<Input, Output> {
        .image()
    }

    /// Creates a custom image snapshot configuration for `UIApplication`.
    ///
    /// This configuration is designed for use with any UI testing framework, allowing you to capture the current UI state after performing user interactions.
    /// It captures the contents of the application's `UIWindow`, making it ideal for verifying visual changes after specific user actions or workflow steps.
    ///
    /// - Parameters:
    ///   - precision: Pixel tolerance for comparison (1 = perfect match, 0.95 = 5% variation allowed).
    ///   - perceptualPrecision: Color/tonal tolerance for perceptual comparison (values closer to 1 require more exact color matching).
    ///   - delay: Delay before capturing the image (useful for waiting for animations or network responses).
    ///   - sessionRole: The role of the UI session (default is `.windowApplication`, appropriate for most UI testing scenarios).
    ///
    /// Example usage with XCUITest (renamed on Xcode 16.3 as XCUIAutomation):
    /// ```swift
    /// let app = XCUIApplication()
    /// app.launch()
    ///
    /// // Perform UI interactions
    /// app.buttons["Submit"].tap()
    ///
    /// // Capture snapshot with custom precision
    /// try assert(
    ///     of: UIApplication.shared,
    ///     as: .image(
    ///         precision: 0.98,
    ///         delay: 2.0
    ///     )
    /// )
    /// ```
    public static func image(
        precision: Float = 1,
        perceptualPrecision: Float = 1,
        delay: Double = .zero,
        sessionRole: UISceneSession.Role = .windowApplication
    ) -> AsyncSnapshot<Input, Output> {
        IdentitySyncSnapshot.image(
            precision: precision,
            perceptualPrecision: perceptualPrecision
        )
        .withApplication(sessionRole: sessionRole) { window, executor in
            Async(Input.self) { _ in window }
                .sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                .map { @MainActor window in
                    let renderer = UIGraphicsImageRenderer(
                        bounds: window.bounds,
                        format: .init(for: window.traitCollection)
                    )

                    let image = try await executor(
                        renderer.image {
                            window.layer.render(in: $0.cgContext)
                        }
                    )

                    return image
                }
        }
        .withLock()
    }
}
#endif
