#if os(macOS)
import AppKit
import Cocoa

extension AsyncSnapshot where Input: NSViewController & Sendable, Output == ImageBytes {
  /// A snapshot strategy for comparing view controller views based on pixel equality.
  public static var image: AsyncSnapshot<Input, Output> {
    return .image()
  }

  /// A snapshot strategy for comparing view controller views based on pixel equality.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
  ///     match. 98-99% mimics
  ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
  ///     human eye.
  ///   - size: A view size override.
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
        .waitLoadingStateIfNeeded(tolerance: SnapshotEnvironment.current.webViewTolerance)
        .snapshot(executor)
      }
    )
    .inconsistentTraitsChecker(config.traits)
    .withLock()
  }
}

extension Snapshot where Input: NSViewController, Output == StringBytes {
  /// A snapshot strategy for comparing viewControllers based on a recursive description of their properties
  /// and hierarchies.
  ///
  /// ``` swift
  /// s// Layout on the current device.
  /// assert(of: viewController, as: .recursiveDescription)
  ///
  /// // Layout with a certain size.
  /// assert(of: viewController, as: .recursiveDescription(size: .init(width: 22, height: 22)))
  ///
  /// // Layout with a certain trait collection.
  /// assert(of: viewController, as: .recursiveDescription(traits: .init(horizontalSizeClass: .regular)))
  /// ```
  ///
  /// Records:
  ///
  /// ```
  /// <UIButton; frame = (0 0; 22 22); opaque = NO; layer = <CALayer>>
  ///    | <UIImageView; frame = (0 0; 22 22); clipsToBounds = YES; opaque = NO; userInteractionEnabled = NO; layer = <CALayer>>
  /// ```
  public static var recursiveDescription: AsyncSnapshot<Input, Output> {
    return .recursiveDescription()
  }

  /// A snapshot strategy for comparing views based on a recursive description of their properties
  /// and hierarchies.
  public static func recursiveDescription(
    drawHierarchyInKeyWindow: Bool = false,
    layout: SnapshotLayout = .sizeThatFits,
    delay: Double = .zero,
    application: NSApplication? = nil
  ) -> AsyncSnapshot<Input, Output> {
    let config = LayoutConfiguration.resolve(layout)

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
          .waitLoadingStateIfNeeded(tolerance: SnapshotEnvironment.current.webViewTolerance)
          .descriptor(executor, method: .subtreeDescription)
        }
      )
      .withLock()
  }
}
#endif
