#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
  import UIKit
#elseif os(macOS)
  @preconcurrency import AppKit
#endif

#if os(iOS) || os(tvOS) || os(visionOS)
  extension AsyncSnapshot where Input: UIKit.UIView, Output == ImageBytes {

    /// Default configuration for capturing `UIView` as image snapshots.
    ///
    /// Notes:
    ///   - Uses default values for precision (`precision: 1`), layout (`sizeThatFits`), and other parameters.
    ///   - Useful for cases where basic configuration meets requirements.
    public static var image: AsyncSnapshot<Input, Output> {
      return .image()
    }

    /// Creates a custom image snapshot configuration for `UIView`.
    ///
    /// - Parameters:
    ///   - drawHierarchyInKeyWindow: When `true`, renders the view hierarchy in the key window
    ///   (useful for window context-dependent layouts).
    ///   - precision: Pixel tolerance for comparison (1 = perfect match, 0.95 = 5% variation allowed).
    ///   - perceptualPrecision: Color/tonal tolerance for perceptual comparison.
    ///   - layout: Defines how the view will be sized (ex: simulating an iPhone 15 Pro Max).
    ///   - traits: Collection of UI traits (orientation, screen size, etc.).
    ///   - delay: Delay before capturing the image (useful for waiting animations).
    ///
    /// - Example:
    ///   ```swift
    ///   let config = Snapshot<UIView, ImageBytes>.image(
    ///       layout: .device(.iPhone15ProMax),
    ///       precision: 0.98
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
    /// ``` swift
    /// s// Layout on the current device.
    /// assert(of: view, as: .recursiveDescription)
    ///
    /// // Layout with a certain size.
    /// assert(of: view, as: .recursiveDescription(size: .init(width: 22, height: 22)))
    ///
    /// // Layout with a certain trait collection.
    /// assert(of: view, as: .recursiveDescription(traits: .init(horizontalSizeClass: .regular)))
    /// ```
    ///
    /// Records:
    ///
    /// ```
    /// <UIButton; frame = (0 0; 22 22); opaque = NO; layer = <CALayer>>
    ///    | <UIImageView; frame = (0 0; 22 22); clipsToBounds = YES; opaque = NO; userInteractionEnabled = NO; layer = <CALayer>>
    /// ```
    public static var recursiveDescription: AsyncSnapshot<Input, Output> {
      return Snapshot.recursiveDescription()
    }

    /// A snapshot strategy for comparing views based on a recursive description of their properties
    /// and hierarchies.
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
