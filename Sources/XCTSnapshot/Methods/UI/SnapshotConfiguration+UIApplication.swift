#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(macOS)
@preconcurrency import AppKit
#endif

#if os(iOS) || os(tvOS)
extension Snapshot where Input: UIKit.UIApplication, Output == ImageBytes {

  /// Default configuration for capturing `UIApplication` as image snapshots.
  ///
  /// Notes:
  ///   - Uses default values for precision (`precision: 1`) and other parameters.
  ///   - Useful for cases where basic configuration meets requirements.
  public static var image: AsyncSnapshot<Input, Output> {
    return .image()
  }

  /// Creates a custom image snapshot configuration for `UIApplication`.
  ///
  /// - Parameters:
  ///   - precision: Pixel tolerance for comparison (1 = perfect match, 0.95 = 5% variation allowed).
  ///   - perceptualPrecision: Color/tonal tolerance for perceptual comparison.
  ///   - traits: Collection of UI traits (orientation, screen size, etc.).
  ///   - delay: Delay before capturing the image (useful for waiting animations).
  ///
  /// - Example:
  ///   ```swift
  ///   let config = Snapshot<UIApplication, ImageBytes>.image(
  ///       precision: 0.98
  ///   )
  ///   ```
  public static func image(
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    traits: UITraitCollection = .init(),
    delay: Double = .zero
  ) -> AsyncSnapshot<Input, Output> {
    return IdentitySyncSnapshot.image(
      precision: precision,
      perceptualPrecision: perceptualPrecision,
      scale: traits.displayScale
    )
    .withApplication { configuration, executor in
      Async(Input.self) { _ in
        configuration.window
      }
      .sleep(nanoseconds: UInt64(delay * 1_000_000_000))
      .map { @MainActor window in
        let renderer = UIGraphicsImageRenderer(
          bounds: window.bounds,
          format: .init(for: window.traitCollection)
        )

        let image = try await executor(ImageBytes(rawValue: renderer.image {
          window.layer.render(in: $0.cgContext)
        }))

        return image
      }
    }
    .withLock()
  }
}
#endif
