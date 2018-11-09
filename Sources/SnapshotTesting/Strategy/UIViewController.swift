#if os(iOS) || os(tvOS)
import UIKit

extension Strategy where Snapshottable == UIViewController, Format == UIImage {
  public static var image: Strategy {
    return .image(precision: 1, size: nil, traits: nil)
  }

  public static func image(precision: Float = 1, size: CGSize) -> Strategy {
    return .image(precision: precision, size: .some(size), traits: nil)
  }

  public static func image(precision: Float = 1, traits: UITraitCollection) -> Strategy {
    return .image(precision: precision, size: nil, traits: .some(traits))
  }

  public static func image(precision: Float = 1, size: CGSize, traits: UITraitCollection) -> Strategy {
    return .image(precision: precision, size: .some(size), traits: .some(traits))
  }

  public static func image(
    on environment: Environment,
    precision: Float = 1,
    traits: UITraitCollection = .init()
    )
    -> Strategy {

      return .image(
        precision: precision,
        size: environment.size,
        traits: UITraitCollection(traitsFrom: [environment.traits, traits])
      )
  }

  private static func image(precision: Float, size: CGSize?, traits: UITraitCollection?) -> Strategy {
    return Strategy<UIView, UIImage>.image(precision: precision, size: size).pullback { vc in
      guard let size = size, let traits = traits else { return vc.view }

      let container = traitController(for: vc, size: size, traits: traits)
      return container.view
    }
  }
}

extension Strategy where Snapshottable == UIViewController, Format == String {
  public static var recursiveDescription: Strategy {
    return Strategy<UIView, String>.recursiveDescription.pullback { $0.view }
  }
}

extension UIViewController: DefaultSnapshottable {
  public static let defaultStrategy: Strategy<UIViewController, UIImage> = .image
}

private func traitController(
  for viewController: UIViewController,
  size: CGSize,
  traits: UITraitCollection = .init())
  -> UIViewController
{

  let parent = UIViewController()
  parent.view.backgroundColor = .white
  parent.view.frame.size = size
  parent.preferredContentSize = parent.view.frame.size
  parent.addChild(viewController)
  parent.view.addSubview(viewController.view)
  parent.setOverrideTraitCollection(traits, forChild: viewController)

  viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
  viewController.view.frame = parent.view.frame

  parent.beginAppearanceTransition(true, animated: false)
  parent.endAppearanceTransition()

  return parent
}

public struct Environment {
  public enum Orientation {
    case landscape
    case portrait
  }

  public let size: CGSize
  public let traits: UITraitCollection

  public init(size: CGSize, traits: UITraitCollection) {
    self.size = size
    self.traits = traits
  }

  #if os(iOS)
  public static let iPhoneSe = Environment.iPhoneSe(.portrait)

  public static func iPhoneSe(_ orientation: Orientation) -> Environment {
    switch orientation {
    case .landscape:
      return Environment(
        size: .init(width: 568, height: 320),
        traits: .init(
          traitsFrom: [
            .init(displayScale: 2),
            .init(horizontalSizeClass: .compact),
            .init(verticalSizeClass: .compact),
            .init(userInterfaceIdiom: .phone)
          ]
        )
      )
    case .portrait:
      return Environment(
        size: .init(width: 320, height: 568),
        traits: .init(
          traitsFrom: [
            .init(displayScale: 2),
            .init(horizontalSizeClass: .compact),
            .init(verticalSizeClass: .regular),
            .init(userInterfaceIdiom: .phone)
          ]
        )
      )
    }
  }

  public static let iPhone8 = Environment.iPhone8(.portrait)

  public static func iPhone8(_ orientation: Orientation) -> Environment {
    switch orientation {
    case .landscape:
      return Environment(
        size: .init(width: 667, height: 375),
        traits: .init(
          traitsFrom: [
            .init(displayScale: 2),
            .init(horizontalSizeClass: .compact),
            .init(verticalSizeClass: .compact),
            .init(userInterfaceIdiom: .phone)
          ]
        )
      )
    case .portrait:
      return Environment(
        size: .init(width: 375, height: 667),
        traits: .init(
          traitsFrom: [
            .init(displayScale: 2),
            .init(horizontalSizeClass: .compact),
            .init(verticalSizeClass: .regular),
            .init(userInterfaceIdiom: .phone)
          ]
        )
      )
    }
  }

  public static let iPhone8Plus = Environment.iPhone8Plus(.portrait)

  public static func iPhone8Plus(_ orientation: Orientation) -> Environment {
    switch orientation {
    case .landscape:
      return Environment(
        size: .init(width: 736, height: 414),
        traits: .init(
          traitsFrom: [
            .init(displayScale: 3),
            .init(horizontalSizeClass: .regular),
            .init(verticalSizeClass: .compact),
            .init(userInterfaceIdiom: .phone)
          ]
        )
      )
    case .portrait:
      return Environment(
        size: .init(width: 414, height: 736),
        traits: .init(
          traitsFrom: [
            .init(displayScale: 3),
            .init(horizontalSizeClass: .compact),
            .init(verticalSizeClass: .regular),
            .init(userInterfaceIdiom: .phone),
          ]
        )
      )
    }
  }

  public static let iPadMini = Environment.iPadMini(.landscape)

  public static func iPadMini(_ orientation: Orientation) -> Environment {
    let size: CGSize
    switch orientation {
    case .landscape:
      size = .init(width: 1024, height: 768)
    case .portrait:
      size = .init(width: 768, height: 1024)
    }
    return Environment(
      size: size,
      traits: .init(
        traitsFrom: [
          .init(displayScale: 2),
          .init(horizontalSizeClass: .regular),
          .init(verticalSizeClass: .regular),
          .init(userInterfaceIdiom: .pad)
        ]
      )
    )
  }

  public static let iPadPro10_5 = Environment.iPadPro10_5(.landscape)

  public static func iPadPro10_5(_ orientation: Orientation) -> Environment {
    let size: CGSize
    switch orientation {
    case .landscape:
      size = .init(width: 1112, height: 834)
    case .portrait:
      size = .init(width: 834, height: 1112)
    }
    return Environment(
      size: size,
      traits: .init(
        traitsFrom: [
          .init(displayScale: 2),
          .init(horizontalSizeClass: .regular),
          .init(verticalSizeClass: .regular),
          .init(userInterfaceIdiom: .pad)
        ]
      )
    )
  }

  public static let iPadPro12_9 = Environment.iPadPro12_9(.landscape)

  public static func iPadPro12_9(_ orientation: Orientation) -> Environment {
    let size: CGSize
    switch orientation {
    case .landscape:
      size = .init(width: 1366, height: 1024)
    case .portrait:
      size = .init(width: 1024, height: 1366)
    }
    return Environment(
      size: size,
      traits: .init(
        traitsFrom: [
          .init(displayScale: 2),
          .init(horizontalSizeClass: .regular),
          .init(verticalSizeClass: .regular),
          .init(userInterfaceIdiom: .pad)
        ]
      )
    )
  }
  #endif
}
#endif
