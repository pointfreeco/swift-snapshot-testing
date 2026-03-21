#if canImport(SwiftUI)
  import Foundation
  import SwiftUI

  /// The size constraint for a snapshot (similar to `PreviewLayout`).
  public enum SwiftUISnapshotLayout {
    #if os(iOS) || os(tvOS)
      /// Center the view in a device container described by`config`.
      case device(config: ViewImageConfig)
      /// Constrain the view to the device width and fit the height to its content.
      ///
      /// Use this layout for views that rely on a container-provided width
      /// (e.g., `containerRelativeFrame`) but should still size their height
      /// to fit content.
      case fillWidth(for: ViewImageConfig)
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
      ///   - drawHierarchyInKeyWindow: Utilize the simulator's key window in order to render
      ///     `UIAppearance` and `UIVisualEffect`s. This option requires a host application for your
      ///     tests and will _not_ work for framework test targets.
      ///   - precision: The percentage of pixels that must match.
      ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a
      ///     match. 98-99% mimics
      ///     [the precision](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) of the
      ///     human eye.
      ///   - layout: A view layout override.
      ///   - traits: A trait collection override.
      public static func image(
        drawHierarchyInKeyWindow: Bool = false,
        precision: Float = 1,
        perceptualPrecision: Float = 1,
        layout: SwiftUISnapshotLayout = .sizeThatFits,
        traits: UITraitCollection = .init()
      )
        -> Snapshotting
      {
        let config: ViewImageConfig
        let fillWidth: CGFloat?

        switch layout {
        #if os(iOS) || os(tvOS)
          case let .device(config: deviceConfig):
            config = deviceConfig
            fillWidth = nil
          case let .fillWidth(for: deviceConfig):
            config = .init(safeArea: .zero, size: nil, traits: deviceConfig.traits ?? traits)
            fillWidth = deviceConfig.size?.width
        #endif
        case .sizeThatFits:
          config = .init(safeArea: .zero, size: nil, traits: traits)
          fillWidth = nil
        case let .fixed(width: width, height: height):
          let size = CGSize(width: width, height: height)
          config = .init(safeArea: .zero, size: size, traits: traits)
          fillWidth = nil
        }

        return SimplySnapshotting.image(
          precision: precision, perceptualPrecision: perceptualPrecision, scale: traits.displayScale
        ).asyncPullback { view in
          var config = config

          let controller: UIViewController

          if let fillWidth {
            let hostingController = UIHostingController(rootView: view)
            let proposed = CGSize(width: fillWidth, height: .greatestFiniteMagnitude)
            config.size = hostingController.sizeThatFits(in: proposed)
            controller = hostingController
          } else if config.size != nil {
            controller = UIHostingController.init(
              rootView: view
            )
          } else if #available(iOS 16.0, tvOS 16.0, *) {
            let colorScheme: ColorScheme = traits.userInterfaceStyle == .dark ? .dark : .light
            let styledView = view.environment(\.colorScheme, colorScheme)
            let displayScale = traits.displayScale

            return Async<UIImage> { callback in
              MainActor.assumeIsolated {
                let renderer = ImageRenderer(content: styledView)
                renderer.proposedSize = ProposedViewSize(width: nil, height: nil)
                renderer.scale = displayScale > 0
                  ? CGFloat(displayScale)
                  : UIScreen.main.scale
                callback(renderer.uiImage ?? UIImage())
              }
            }
          } else {
            let hostingController = UIHostingController.init(rootView: view)
            let screenWidth = UIScreen.main.bounds.width
            let proposed = CGSize(width: screenWidth, height: .greatestFiniteMagnitude)
            config.size = hostingController.sizeThatFits(in: proposed)

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
  #endif
#endif
