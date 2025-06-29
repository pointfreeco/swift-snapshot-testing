import Foundation

#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit

private struct TraitsEnvironmentKey: SnapshotEnvironmentKey {
    static let defaultValue = Traits()
}

extension SnapshotEnvironmentValues {

    /// Provides access to the `Traits` configuration for snapshot testing.
    ///
    /// This property allows you to customize the appearance and behavior of
    /// UI elements during snapshot testing by specifying traits like
    /// accessibility features, color schemes, or device characteristics.
    ///
    /// Example:
    /// ```swift
    /// // Configure traits for snapshot testing
    /// withTestingEnvironment {
    ///     $0.traits = .init(preferredContentSizeCategory: .extraLarge)
    /// } operation: {
    ///     // Your testing code here
    /// }
    /// ```
    ///
    /// - Note: Traits can be combined to simulate various UI conditions during testing.
    /// - SeeAlso:
    ///     - ``Traits``
    ///     - ``withTestingEnvironment(_:operation:file:line:)``
    public var traits: Traits {
        get { self[TraitsEnvironmentKey.self] }
        set { self[TraitsEnvironmentKey.self] = newValue }
    }
}
#endif
