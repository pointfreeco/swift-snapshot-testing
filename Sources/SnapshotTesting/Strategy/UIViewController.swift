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

      let environmentTraits = environment.device.traits(for: environment.orientation)
      let traits = UITraitCollection(traitsFrom: [environmentTraits, traits])

      return .image(
        precision: precision,
        size: environment.device.size(for: environment.orientation),
        traits: traits
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

#if os(iOS)
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
  fileprivate let device: Device
  fileprivate let orientation: Orientation

  public static let iPhoneSe = Environment(device: .iPhoneSe, orientation: .portrait)

  public static func iPhoneSe(_ orientation: Orientation) -> Environment {
    return Environment(device: .iPhoneSe, orientation: orientation)
  }

  public static let iPhone8 = Environment(device: .iPhone8, orientation: .portrait)

  public static func iPhone8(_ orientation: Orientation) -> Environment {
    return Environment(device: .iPhone8, orientation: orientation)
  }

  public static let iPhone8Plus = Environment(device: .iPhone8Plus, orientation: .portrait)

  public static func iPhone8Plus(_ orientation: Orientation) -> Environment {
    return Environment(device: .iPhone8Plus, orientation: orientation)
  }

  public static let iPadMini = Environment(device: .iPadMini, orientation: .landscape)

  public static func iPadMini(_ orientation: Orientation) -> Environment {
    return Environment(device: .iPadMini, orientation: orientation)
  }

  public static let iPadPro10_5 = Environment(device: .iPadPro10_5, orientation: .landscape)

  public static func iPadPro10_5(_ orientation: Orientation) -> Environment {
    return Environment(device: .iPadPro10_5, orientation: orientation)
  }

  public static let iPadPro12_9 = Environment(device: .iPadPro12_9, orientation: .landscape)

  public static func iPadPro12_9(_ orientation: Orientation) -> Environment {
    return Environment(device: .iPadPro12_9, orientation: orientation)
  }
}

private enum Device {
  case iPhoneSe
  case iPhone8
  case iPhone8Plus
  case iPadMini
  case iPadPro10_5
  case iPadPro12_9

  fileprivate func size(for orientation: Orientation) -> CGSize {
    switch orientation {
    case .portrait:
      return self.portraitSize
    case .landscape:
      return self.landscapeSize
    }
  }

  fileprivate func traits(for orientation: Orientation) -> UITraitCollection {
    switch (self, orientation) {
    case (.iPhoneSe, .portrait), (.iPhone8, .portrait):
      return .init(
        traitsFrom: [
          .init(displayScale: 2),
          .init(horizontalSizeClass: .compact),
          .init(verticalSizeClass: .regular),
          .init(userInterfaceIdiom: .phone)
        ]
      )
    case (.iPhone8Plus, .portrait):
      return .init(
        traitsFrom: [
          .init(displayScale: 3),
          .init(horizontalSizeClass: .compact),
          .init(verticalSizeClass: .regular),
          .init(userInterfaceIdiom: .phone),
        ]
      )
    case (.iPhoneSe, .landscape), (.iPhone8, .landscape):
      return .init(
        traitsFrom: [
          .init(displayScale: 2),
          .init(horizontalSizeClass: .compact),
          .init(verticalSizeClass: .compact),
          .init(userInterfaceIdiom: .phone)
        ]
      )
    case (.iPhone8Plus, .landscape):
      return .init(
        traitsFrom: [
          .init(displayScale: 3),
          .init(horizontalSizeClass: .regular),
          .init(verticalSizeClass: .compact),
          .init(userInterfaceIdiom: .phone)
        ]
      )
    case (.iPadMini, _), (.iPadPro10_5, _), (.iPadPro12_9, _):
      return .init(
        traitsFrom: [
          .init(displayScale: 2),
          .init(horizontalSizeClass: .regular),
          .init(verticalSizeClass: .regular),
          .init(userInterfaceIdiom: .pad)
        ]
      )
    }
  }

  private var portraitSize: CGSize {
    switch self {
    case .iPhoneSe:
      return .init(width: 320, height: 568)
    case .iPhone8:
      return .init(width: 375, height: 667)
    case .iPhone8Plus:
      return .init(width: 414, height: 736)
    case .iPadMini:
      return .init(width: 768, height: 1024)
    case .iPadPro10_5:
      return .init(width: 834, height: 1112)
    case .iPadPro12_9:
      return .init(width: 1024, height: 1366)
    }
  }

  private var landscapeSize: CGSize {
    let portraitSize = self.portraitSize
    return .init(width: portraitSize.height, height: portraitSize.width)
  }
}

public enum Orientation {
  case portrait
  case landscape
}
#endif
#endif
