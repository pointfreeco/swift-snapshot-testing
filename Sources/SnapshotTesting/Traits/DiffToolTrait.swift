import Foundation
import Testing
@_spi(Internals) import XCSnapshotTesting

public struct DiffToolTrait: SuiteTrait, TestTrait {
    public let isRecursive = true
    let diffTool: DiffTool
}

extension Trait where Self == DiffToolTrait {

    /// Returns a trait that specifies a custom diff tool for snapshot comparisons.
    ///
    /// Use this method to override the default diff tool used by snapshot testing frameworks
    /// when comparing reference images or files. This is useful for customizing how differences are presented,
    /// such as by launching a specific visual diff application or using a particular command-line utility.
    ///
    /// - Parameter diffTool: The `DiffTool` instance to use for diffing snapshots within the scope of this trait.
    /// - Returns: A `DiffToolTrait` that can be applied at the suite or test level.
    ///
    /// Example usage:
    /// ```swift
    /// @Suite(.diffTool(.ksdiff))
    /// struct MySnapshotTests { ... }
    /// ```
    public static func diffTool(_ diffTool: DiffTool) -> Self {
        .init(diffTool: diffTool)
    }
}
