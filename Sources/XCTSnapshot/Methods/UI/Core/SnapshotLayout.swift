#if os(macOS) || os(iOS) || os(tvOS) || os(visionOS) || os(watchOS)
import CoreGraphics

/// Defines how a UI component's layout is configured during snapshot testing.
public enum SnapshotLayout {

    #if os(iOS) || os(tvOS) || os(visionOS)
    /// Renders the component using a specific device configuration.
    ///
    /// - Parameter configuration: Layout configuration defining safe area margins, size,
    /// and UI traits (e.g., orientation).
    ///
    /// Example:
    ///   ```swift
    ///   let layout = .device(.iPhone15ProMax)
    ///   ```
    case device(LayoutConfiguration)
    #endif

    /// Renders the component with an explicit fixed size.
    ///
    /// Useful for ensuring test consistency across devices or configurations.
    ///
    /// - Parameters:
    ///   - width: Width in points.
    ///   - height: Height in points.
    ///
    /// Example:
    ///   ```swift
    ///   let layout = .fixed(width: 375, height: 812) // iPhone 12 dimensions
    ///   ```
    case fixed(width: CGFloat, height: CGFloat)

    /// Renders the component using its natural intrinsic content size.
    ///
    /// Ideal for content-adaptive components like labels or dynamic collections.
    case sizeThatFits
}
#endif
