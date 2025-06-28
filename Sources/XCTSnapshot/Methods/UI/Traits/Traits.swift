#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
#elseif os(macOS)
@preconcurrency import AppKit
#endif

#if os(iOS) || os(tvOS) || os(visionOS)
protocol TraitKey: Sendable, Hashable {

    associatedtype Value: Hashable & Sendable

    static var defaultValue: Value { get }

    @available(iOS 17, tvOS 17, *)
    @MainActor
    static func apply(_ value: Value, to traitsOverrides: inout UITraitOverrides)

    @MainActor
    static func apply(_ value: Value, to traitCollection: inout UITraitCollection)
}

/// A set of characteristics that describe the environment in which UI elements are displayed during snapshot testing.
///
/// `Traits` allows you to customize the appearance and behavior of UI elements by specifying various display and accessibility characteristics.
/// These traits help ensure that your UI renders correctly across different devices and configurations during testing.
///
/// ```swift
/// let traits = Traits(preferredContentSizeCategory: .extraLarge)
/// SnapshotEnvironment.current.traits = traits
/// ```
public struct Traits: Sendable, Hashable {

    private var traits = [ObjectIdentifier: Storage]()

    /// Creates a default `Traits` instance with no specific characteristics set.
    public init() {}

    /// Creates a `Traits` instance from a collection of trait dictionaries.
    public init(traitsFrom traitCollection: [Traits]) {
        self.init(
            traitCollection.lazy.map(\.traits).reduce([:]) {
                $0.merging($1, uniquingKeysWith: { $1 })
            }
        )
    }

    private init(_ traits: [ObjectIdentifier: Storage]) {
        self.traits = traits
    }

    subscript<Key: TraitKey>(_ key: Key.Type) -> Key.Value {
        get {
            let id = ObjectIdentifier(key)

            guard let storage = traits[id] else {
                return key.defaultValue
            }

            return storage.value as! Key.Value
        }
        set {
            let id = ObjectIdentifier(key)
            traits[id, default: .init(key)].value = newValue
        }
    }

    /// Combines this traits instance with another, returning a new instance that merges the properties of both.
    public func merging(_ traits: Traits) -> Traits {
        .init(traitsFrom: [self, traits])
    }

    /// Returns a `UITraitCollection` representation of these traits.
    public func callAsFunction() -> UITraitCollection {
        performOnMainThread {
            traits.reduce(into: UITraitCollection()) {
                $1.value.apply(to: &$0)
            }
        }
    }

    @MainActor
    func commit(in viewController: UIViewController) {
        #if !os(visionOS)
        var pendingTraitCollection: UITraitCollection?
        #endif

        for (_, trait) in traits {
            #if os(visionOS)
            trait.apply(to: &viewController.traitOverrides)
            #else
            if #available(iOS 17, tvOS 17, *) {
                trait.apply(to: &viewController.traitOverrides)
            } else {
                var traitCollection = pendingTraitCollection ?? UITraitCollection()
                trait.apply(to: &traitCollection)
                pendingTraitCollection = traitCollection
            }
            #endif
        }

        #if !os(visionOS)
        guard let pendingTraitCollection else {
            return
        }

        for childViewController in viewController.children {
            viewController.setOverrideTraitCollection(
                pendingTraitCollection,
                forChild: childViewController
            )
        }
        #endif
    }
}

private struct Storage: Sendable, Hashable {

    var value: any Hashable & Sendable

    private let mutating: @MainActor (Self, inout Any) -> Void
    private let asserting: @Sendable (Self, Self) -> Bool
    private let hashing: @Sendable (Self, inout Hasher) -> Void

    init<Key: TraitKey>(_ key: Key.Type) {
        value = Key.defaultValue
        mutating = {
            #if os(visionOS)
            if var traitsOverrides = $1 as? UITraitOverrides {
                key.apply($0.value as! Key.Value, to: &traitsOverrides)
                $1 = traitsOverrides
            } else {
                var traitCollection = $1 as! UITraitCollection
                key.apply($0.value as! Key.Value, to: &traitCollection)
                $1 = traitCollection
            }
            #else
            if #available(iOS 17, tvOS 17, *), var traitsOverrides = $1 as? UITraitOverrides {
                key.apply($0.value as! Key.Value, to: &traitsOverrides)
                $1 = traitsOverrides
            } else {
                var traitCollection = $1 as! UITraitCollection
                key.apply($0.value as! Key.Value, to: &traitCollection)
                $1 = traitCollection
            }
            #endif
        }
        asserting = {
            if let lhs = $0.value as? Key.Value, let rhs = $1.value as? Key.Value {
                return lhs == rhs
            } else {
                return false
            }
        }
        hashing = {
            let value = $0.value as! Key.Value
            value.hash(into: &$1)
        }
    }

    static func == (_ lhs: Self, _ rhs: Self) -> Bool {
        lhs.asserting(lhs, rhs)
    }

    func hash(into hasher: inout Hasher) {
        hashing(self, &hasher)
    }

    @available(iOS 17, tvOS 17, *)
    @MainActor
    func apply(to traitsOverrides: inout UITraitOverrides) {
        var reference = traitsOverrides as Any
        mutating(self, &reference)
        traitsOverrides = reference as! UITraitOverrides
    }

    @MainActor
    func apply(to traitCollection: inout UITraitCollection) {
        var reference = traitCollection as Any
        mutating(self, &reference)
        traitCollection = reference as! UITraitCollection
    }
}

extension Traits {

    func inconsistentTraitsChecker<Object>(_ object: Object, to otherTraits: Traits) {
        if self != otherTraits {
            guard !SnapshotEnvironment.current.disableInconsistentTraitsChecker else {
                print("[DISABLED] ⚠️ Inconsistent Traits Detected - Snapshot Integrity Risk")
                return
            }

            print(
                """
                ⚠️ Inconsistent Traits Detected - Snapshot Integrity Risk

                The same instance of \(type(of: object)) is being reused with a different \(Traits.self) \
                configuration.

                This may cause:
                - Unreliable snapshot comparisons
                - State contamination between test runs
                - Non-deterministic test failures

                🛠️ Recommended approach for reliable snapshot testing:

                  try await assert(
                    of: await \(type(of: object))(), // Always use a clean instance
                    as: ...
                  )

                ℹ️ Tip: Create fresh input instances for each test scenario to ensure consistent results.
                """
            )
        }
    }
}

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
        var traits = Traits(
            deviceInterfaceSizeClass: deviceInterfaceSizeClass(size)
        )

        #if os(tvOS)
        traits.userInterfaceIdiom = .tv
        #else
        traits.userInterfaceIdiom = userInterfaceIdiom
        #endif
        traits.displayScale = displayScale

        return traits
    }
}
#endif
