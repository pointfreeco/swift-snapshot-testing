#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
#elseif os(macOS)
@preconcurrency import AppKit
#endif

#if os(visionOS)
public struct Traits: Sendable {

  private let mutating: @Sendable (inout any UIMutableTraits) -> Void

  public init(_ mutating: @escaping @Sendable (inout any UIMutableTraits) -> Void) {
    self.mutating = mutating
  }

  public init() {
    self.mutating = { _ in }
  }

  public func merging(_ traits: Traits) -> Traits {
    .init {
      mutating(&$0)
      traits.mutating(&$0)
    }
  }

  public func callAsFunction() -> UITraitCollection {
    return UITraitCollection(mutations: mutating)
  }

  @MainActor
  func commit(in viewController: UIViewController) {
    var traits = viewController.traitOverrides as (any UIMutableTraits)
    mutating(&traits)
    viewController.traitOverrides = traits as! UITraitOverrides
  }
}
#elseif os(tvOS) || os(iOS)
extension UITraitCollection {

  func callAsFunction() -> UITraitCollection {
    self
  }

  @MainActor
  func commit(in viewController: UIViewController) {
    for childViewController in viewController.children {
      viewController.setOverrideTraitCollection(
        self,
        forChild: childViewController
      )
    }
  }

  func merging(_ traits: UITraitCollection) -> UITraitCollection {
    .init(traitsFrom: [self, traits])
  }
}

public typealias Traits = UITraitCollection
#endif

#if os(iOS) || os(tvOS) || os(visionOS)
extension Traits {

  static func iOS(
    displayScale: CGFloat,
    size: CGSize,
    deviceInterfaceSizeClass: DeviceDynamicInterfaceSizeClass
  ) -> Traits {
    iOS(
      userInterfaceIdiom: .phone,
      displayScale: displayScale,
      size: size,
      deviceInterfaceSizeClass: deviceInterfaceSizeClass
    )
  }

  static func iPadOS(
    displayScale: CGFloat,
    size: CGSize,
    deviceInterfaceSizeClass: DeviceDynamicInterfaceSizeClass
  ) -> Traits {
    iOS(
      userInterfaceIdiom: .pad,
      displayScale: displayScale,
      size: size,
      deviceInterfaceSizeClass: deviceInterfaceSizeClass
    )
  }

  static func tvOS(
    displayScale: CGFloat,
    size: CGSize,
    deviceInterfaceSizeClass: DeviceDynamicInterfaceSizeClass
  ) -> Traits {
    iOS(
      userInterfaceIdiom: .tv,
      displayScale: displayScale,
      size: size,
      deviceInterfaceSizeClass: deviceInterfaceSizeClass
    )
  }

  @available(iOS 17, tvOS 17, *)
  static func visionOS(
    displayScale: CGFloat,
    size: CGSize,
    deviceInterfaceSizeClass: DeviceDynamicInterfaceSizeClass
  ) -> Traits {
    iOS(
      userInterfaceIdiom: .vision,
      displayScale: displayScale,
      size: size,
      deviceInterfaceSizeClass: deviceInterfaceSizeClass
    )
  }

  private static func iOS(
    userInterfaceIdiom: UIUserInterfaceIdiom = .phone,
    displayScale: CGFloat,
    size: CGSize,
    deviceInterfaceSizeClass: DeviceDynamicInterfaceSizeClass
  ) -> Traits {
    let deviceInterfaceSizeClassTrait = Traits(
      deviceInterfaceSizeClass: deviceInterfaceSizeClass(size)
    )

    let traits: Traits

    #if os(visionOS)
    traits = Traits {
      $0.userInterfaceIdiom = userInterfaceIdiom
      $0.displayScale = displayScale
    }
    #else
    traits = Traits(traitsFrom: [
      .init(userInterfaceIdiom: userInterfaceIdiom),
      .init(displayScale: displayScale)
    ])
    #endif

    return traits.merging(deviceInterfaceSizeClassTrait)
  }
}
#endif
