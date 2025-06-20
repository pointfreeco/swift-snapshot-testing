@preconcurrency import SwiftUI

#if os(macOS)
extension AsyncSnapshot where Input: SwiftUI.View & Sendable, Output == ImageBytes {

  /// Default configuration for capturing `View` as image snapshots.
  ///
  /// Notes:
  ///   - Renders the controller's view in its initial state
  ///   - Uses default values for precision and layout
  public static var image: AsyncSnapshot<Input, Output> {
    return .image()
  }

  /// Creates a custom image snapshot configuration for `View`.
  ///
  /// - Parameters:
  ///   - drawHierarchyInKeyWindow: When `true`, renders the view hierarchy in the key window
  ///   (useful for window context-dependent layouts)
  ///   - precision: Pixel tolerance for comparison (1 = perfect match, 0.95 = 5% variation allowed)
  ///   - perceptualPrecision: Color/tonal tolerance for perceptual comparison
  ///   - layout: Defines how the view will be sized (ex: simulating an iPhone 15 Pro Max)
  ///   - delay: Delay before capturing the image (useful for waiting animations)
  ///
  /// - Example:
  ///   ```swift
  ///   let config = Snapshot<Text, ImageBytes>.image(
  ///       layout: .device(.iPhone15ProMax),
  ///       precision: 0.98
  ///   )
  ///   ```
  public static func image(
    drawHierarchyInKeyWindow: Bool = false,
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    layout: SnapshotLayout = .sizeThatFits,
    delay: Double = .zero,
    application: NSApplication? = nil
  ) -> AsyncSnapshot<Input, Output> {
    let config = LayoutConfiguration.resolve(layout)

    return IdentitySyncSnapshot.image(
      precision: precision,
      perceptualPrecision: perceptualPrecision,
      scale: 1.0
    )
    .withWindow(
      drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
      application: application,
      operation: { windowConfiguration, executor in
        Async(Input.self) { @MainActor in
          SnapshotUIController($0, with: config)
        }
        .connectToWindow(windowConfiguration)
        .layoutIfNeeded()
        .sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        .waitLoadingStateIfNeeded(tolerance: SnapshotEnvironment.webViewTolerance)
        .snapshot(executor)
      }
    )
  }
}
#elseif os(iOS) || os(tvOS) || os(visionOS)
extension Snapshot where Input: SwiftUI.View & Sendable, Output == ImageBytes {

  /// Default configuration for capturing `View` as image snapshots.
  ///
  /// Notes:
  ///   - Renders the controller's view in its initial state
  ///   - Uses default values for precision and layout
  public static var image: AsyncSnapshot<Input, Output> {
    return .image()
  }

  /// Creates a custom image snapshot configuration for `View`.
  ///
  /// - Parameters:
  ///   - drawHierarchyInKeyWindow: When `true`, renders the view hierarchy in the key window
  ///   (useful for window context-dependent layouts)
  ///   - precision: Pixel tolerance for comparison (1 = perfect match, 0.95 = 5% variation allowed)
  ///   - perceptualPrecision: Color/tonal tolerance for perceptual comparison
  ///   - layout: Defines how the view will be sized (ex: simulating an iPhone 15 Pro Max)
  ///   - traits: Collection of UI traits (orientation, screen size, etc.)
  ///   - delay: Delay before capturing the image (useful for waiting animations)
  ///
  /// - Example:
  ///   ```swift
  ///   let config = Snapshot<Text, ImageBytes>.image(
  ///       layout: .device(.iPhone15ProMax),
  ///       precision: 0.98
  ///   )
  ///   ```
  public static func image(
    drawHierarchyInKeyWindow: Bool = false,
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    layout: SnapshotLayout = .sizeThatFits,
    traits: Traits = .init(),
    delay: Double = .zero,
    application: UIKit.UIApplication? = nil
  ) -> AsyncSnapshot<Input, Output> {
    let config = LayoutConfiguration.resolve(
      layout,
      with: SnapshotEnvironment.traits.merging(traits)
    )

    return IdentitySyncSnapshot.image(
      precision: precision,
      perceptualPrecision: perceptualPrecision,
      scale: config.traits().displayScale
    )
    .withWindow(
      drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
      application: application,
      operation: { windowConfiguration, executor in
        Async(Input.self) { @MainActor in
          SnapshotUIController($0, with: config)
        }
        .connectToWindow(windowConfiguration)
        .layoutIfNeeded()
        .sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        #if !os(tvOS)
        .waitLoadingStateIfNeeded(tolerance: SnapshotEnvironment.webViewTolerance)
        #endif
        .snapshot(executor)
      }
    )
  }
}
#elseif os(watchOS)
@available(watchOS, introduced: 9.0)
extension Snapshot where Input: SwiftUI.View & Sendable, Output == ImageBytes {

  public static var image: AsyncSnapshot<Input, Output> {
    return .image()
  }

  public static func image(
    precision: Float = 1,
    scale: CGFloat = 1,
    layout: SnapshotLayout = .sizeThatFits
  ) -> AsyncSnapshot<Input, Output> {
    let config = LayoutConfiguration.resolve(layout)

    return IdentitySyncSnapshot<ImageBytes>.image(
      precision: precision,
      scale: scale
    ).map { executor in
      Async(Input.self) { @MainActor view in
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale

        if let size = config.size {
          renderer.proposedSize = .init(size)
        }
        
        return try await executor(
          ImageBytes(rawValue: renderer.uiImage ?? UIImage())
        )
      }
    }
  }
}
#endif
