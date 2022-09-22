#if canImport(SwiftUI)
import Foundation
import SwiftUI

/// The size constraint for a snapshot (similar to `PreviewLayout`).
public enum SwiftUISnapshotLayout {
  #if os(iOS) || os(tvOS)
  /// Center the view in a device container described by`config`.
  case device(config: ViewImageConfig)
  #endif
  /// Center the view in a fixed size container.
  case fixed(width: CGFloat, height: CGFloat)
  /// Fit the view to the ideal size that fits its content.
  case sizeThatFits
}

#if os(iOS) || os(tvOS)
@available(iOS 13.0, tvOS 13.0, *)
extension Snapshotting where Value: SwiftUI.View, Format == UIImage {

  /// A snapshot strategy for comparing SwiftUI Views based on pixel equality.
  public static var image: Snapshotting {
    return .image()
  }

  /// A snapshot strategy for comparing SwiftUI Views based on pixel equality.
  ///
  /// - Parameters:
  ///   - drawHierarchyInKeyWindow: Utilize the simulator's key window in order to render `UIAppearance` and `UIVisualEffect`s. This option requires a host application for your tests and will _not_ work for framework test targets.
  ///   - precision: The percentage of pixels that must match.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match. [98-99% mimics the precision of the human eye.](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e)
  ///   - layout: A view layout override.
  ///   - traits: A trait collection override.
  public static func image(
    drawHierarchyInKeyWindow: Bool = false,
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    layout: SwiftUISnapshotLayout = .sizeThatFits,
    traits: UITraitCollection = .init()
    )
    -> Snapshotting {
      let config: ViewImageConfig

      switch layout {
      #if os(iOS) || os(tvOS)
      case let .device(config: deviceConfig):
        config = deviceConfig
      #endif
      case .sizeThatFits:
        config = .init(safeArea: .zero, size: nil, traits: traits)
      case let .fixed(width: width, height: height):
        let size = CGSize(width: width, height: height)
        config = .init(safeArea: .zero, size: size, traits: traits)
      }

      return SimplySnapshotting.image(precision: precision, perceptualPrecision: perceptualPrecision, scale: traits.displayScale).asyncPullback { view in
        var config = config

        let controller: UIViewController

        if config.size != nil {
          controller = UIHostingController.init(
            rootView: view
          )
        } else {
          let hostingController = UIHostingController.init(rootView: view)

          let maxSize = CGSize(width: 0.0, height: 0.0)
          config.size = hostingController.sizeThatFits(in: maxSize)

          controller = hostingController
        }

        return snapshotView(
          config: config,
          drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
          traits: traits,
          view: controller.view,
          viewController: controller
        )
      }
  }
}

#if compiler(>=5.7)
@available(iOS 16.0, tvOS 16.0, *)
extension Snapshotting where Value: SwiftUI.View, Format == UIImage {

  /// A snapshot strategy for comparing SwiftUI Views based on pixel equality using iOS 16 ImageRenderer.
  public static var imageRenderer: Snapshotting {
    return .imageRenderer()
  }

  /// A snapshot strategy for comparing SwiftUI Views based on pixel equality using iOS 16 ImageRenderer.
  ///
  /// - Parameters:
  ///   - precision: The percentage of pixels that must match.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match. [98-99% mimics the precision of the human eye.](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e)
  ///   - layout: A view layout override.
  ///   - proposedSize: The size proposed to the view. See ``SwiftUI/ImageRenderer/proposedSize``.
  ///   - scale: The scale at which to render the image. See ``SwiftUI/ImageRenderer/scale``.
  ///   - isOpaque: A Boolean value that indicates whether the alpha channel of the image is fully opaque. See ``SwiftUI/ImageRenderer/isOpaque``.
  ///   - colorMode: The working color space and storage format of the image. See ``SwiftUI/ImageRenderer/colorMode``.
  static func imageRenderer(
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    layout: SwiftUISnapshotLayout = .sizeThatFits,
    proposedSize: ProposedViewSize = .unspecified,
    scale: CGFloat = 1.0,
    isOpaque: Bool = false,
    colorMode: ColorRenderingMode = .nonLinear
    )
    -> Snapshotting {
      return SimplySnapshotting.image(precision: precision, perceptualPrecision: perceptualPrecision, scale: scale).asyncPullback { view in
        return .init { callback in
          Task { @MainActor in
            let renderer = ImageRenderer(
              content: SnapshottingView(layout: layout, content: view)
            )
            renderer.proposedSize = proposedSize
            renderer.scale = scale
            renderer.isOpaque = isOpaque
            renderer.colorMode = colorMode

            callback(renderer.uiImage ?? UIImage())
          }
        }
      }
  }
}

@available(iOS 16.0, tvOS 16.0, *)
private struct SnapshottingView<Content: SwiftUI.View>: SwiftUI.View {
  let layout: SwiftUISnapshotLayout
  let content: Content

  var body: some SwiftUI.View {
    switch layout {
    case let .device(config):
      ZStack {
        Color(uiColor: UIColor.systemBackground)
          .ignoresSafeArea()

        content
      }
      .safeAreaInset(edge: .top, spacing: 0) { Spacer().frame(height: config.safeArea.top) }
      .safeAreaInset(edge: .bottom, spacing: 0) { Spacer().frame(height: config.safeArea.bottom) }
      .safeAreaInset(edge: .leading, spacing: 0) { Spacer().frame(width: config.safeArea.left) }
      .safeAreaInset(edge: .trailing, spacing: 0) { Spacer().frame(width: config.safeArea.right) }
      .modifier(TraitsModifier(traits: config.traits))
      .frame(width: config.size?.width, height: config.size?.height)

    case let .fixed(width, height):
      content
        .frame(width: width, height: height)
        .background(Color(uiColor: UIColor.systemBackground))

    case .sizeThatFits:
      content
    }
  }
}

@available(iOS 16.0, tvOS 16.0, *)
private struct TraitsModifier: ViewModifier {
  let traits: UITraitCollection

  func body(content: Content) -> some SwiftUI.View {
    content
      .environment(\.horizontalSizeClass, UserInterfaceSizeClass(traits.horizontalSizeClass))
      .environment(\.verticalSizeClass, UserInterfaceSizeClass(traits.verticalSizeClass))
      .transformEnvironment(\.layoutDirection) { direction in
        direction = LayoutDirection(traits.layoutDirection) ?? direction
      }
      .transformEnvironment(\.dynamicTypeSize) { typeSize in
        typeSize = DynamicTypeSize(traits.preferredContentSizeCategory) ?? typeSize
      }
  }
}
#endif
#endif
#endif
