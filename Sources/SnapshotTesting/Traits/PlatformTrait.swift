import Foundation
import Testing
@_spi(Internals) import XCSnapshotTesting

public struct PlatformTrait: SuiteTrait, TestTrait {
    public let isRecursive = true
    let platform: String
}

extension Trait where Self == PlatformTrait {

    /// Adds a platform trait to a test or suite, allowing it to be conditionally
    /// included or configured based on the specified platform identifier.
    ///
    /// You can use this trait to annotate tests for filtering or to provide specialized
    /// behaviors on certain platforms (such as "iOS", "macOS", "watchOS", or "visionOS").
    ///
    /// Example usage:
    ///
    ///     @Suite(.platform("iOS"))
    ///
    /// - Parameter platform: An optional string specifying the platform identifier.
    ///
    /// - Returns: A `PlatformTrait` configured with the given platform.
    ///
    /// - Note: Setting this value to `nil` or an empty string (e.g., `.platform(nil)` or `.platform("")`) makes all snapshots for this suite or test shared between platforms, removing any platform-specific distinction.
    public static func platform(_ platform: String?) -> Self {
        .init(platform: platform ?? "")
    }
}
