#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
  import UIKit
#elseif os(macOS)
  @preconcurrency import AppKit
#endif

#if os(iOS) || os(tvOS) || os(visionOS)
  extension AsyncSnapshot where Input: UIKit.UIViewController, Output == ImageBytes {

    public static var image: AsyncSnapshot<Input, Output> {
      return .image()
    }

    /// Creates a custom image snapshot configuration for `UIViewController`.
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
    ///   let config = Snapshot<UIViewController, ImageBytes>.image(
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
        with: SnapshotEnvironment.current.traits.merging(traits)
      )

      return IdentitySyncSnapshot.image(
        precision: precision,
        perceptualPrecision: perceptualPrecision
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

    /// A snapshot strategy for comparing view controllers based on their embedded controller
    /// hierarchy.
    ///
    /// ``` swift
    /// assert(of: vc, as: .hierarchy)
    /// ```
    ///
    /// Records:
    ///
    /// ```
    /// <UITabBarController>, state: appeared, view: <UILayoutContainerView>
    ///    | <UINavigationController>, state: appeared, view: <UILayoutContainerView>
    ///    |    | <UIPageViewController>, state: appeared, view: <_UIPageViewControllerContentView>
    ///    |    |    | <UIViewController>, state: appeared, view: <UIView>
    ///    | <UINavigationController>, state: disappeared, view: <UILayoutContainerView> not in the window
    ///    |    | <UIViewController>, state: disappeared, view: (view not loaded)
    ///    | <UINavigationController>, state: disappeared, view: <UILayoutContainerView> not in the window
    ///    |    | <UIViewController>, state: disappeared, view: (view not loaded)
    ///    | <UINavigationController>, state: disappeared, view: <UILayoutContainerView> not in the window
    ///    |    | <UIViewController>, state: disappeared, view: (view not loaded)
    ///    | <UINavigationController>, state: disappeared, view: <UILayoutContainerView> not in the window
    ///    |    | <UIViewController>, state: disappeared, view: (view not loaded)
    /// ```
    public static var hierarchy: AsyncSnapshot<Input, Output> {
      Snapshot.hierarchy()
    }

    /// A snapshot strategy for comparing view controller views based on a recursive description of
    /// their properties and hierarchies.
    public static var recursiveDescription: AsyncSnapshot<Input, Output> {
      Snapshot.recursiveDescription()
    }

    public static func hierarchy(
      drawHierarchyInKeyWindow: Bool = false,
      layout: SnapshotLayout = .sizeThatFits,
      traits: Traits = .init(),
      delay: Double = .zero,
      application: UIKit.UIApplication? = nil
    ) -> AsyncSnapshot<Input, Output> {
      descriptor(
        method: .hierarchy,
        drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
        layout: layout,
        traits: traits,
        delay: delay,
        application: application
      )
    }

    /// A snapshot strategy for comparing view controller views based on a recursive description of
    /// their properties and hierarchies.
    ///
    /// - Parameters:
    ///   - config: A set of device configuration settings.
    ///   - size: A view size override.
    ///   - traits: A trait collection override.
    public static func recursiveDescription(
      drawHierarchyInKeyWindow: Bool = false,
      layout: SnapshotLayout = .sizeThatFits,
      traits: Traits = .init(),
      delay: Double = .zero,
      application: UIKit.UIApplication? = nil
    ) -> AsyncSnapshot<Input, Output> {
      descriptor(
        method: .recursiveDescription,
        drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
        layout: layout,
        traits: traits,
        delay: delay,
        application: application
      )
    }

    private static func descriptor(
      method: SnapshotUIController.DescriptorMethod,
      drawHierarchyInKeyWindow: Bool,
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
              .waitLoadingStateIfNeeded(tolerance: SnapshotEnvironment.current.webViewTolerance)
            #endif
            .descriptor(executor, method: method)
          }
        )
        .withLock()
    }
  }
#endif
