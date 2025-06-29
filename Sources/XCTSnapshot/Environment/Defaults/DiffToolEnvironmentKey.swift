import Foundation

private struct DiffToolEnvironmentKey: SnapshotEnvironmentKey {

    static var defaultValue: DiffTool {
        TestingSystem.shared.environment?.diffTool ?? .default
    }
}

extension SnapshotEnvironmentValues {

    /// The `diffTool` property provides access to the current diff tool configuration within the snapshot testing environment.
    ///
    /// This property allows you to specify or retrieve the tool used for visual comparisons when snapshot tests fail.
    /// It can be accessed globally through `SnapshotEnvironment.current.diffTool`.
    ///
    /// The value defaults to `.default`, which provides a basic textual comparison output in the Xcode console.
    /// You can change this value using:
    /// - `withTestingEnvironment(diffTool:operation:)`
    /// - Swift Testing framework attributes
    ///
    /// Available diff tools include:
    /// - `.default`: Basic console output with instructions for configuring advanced diff tools
    /// - `.ksdiff`: Launches Kaleidoscope for visual comparison (requires Kaleidoscope installation)
    ///
    /// ```swift
    /// // Accessing the current diff tool
    /// let currentTool = SnapshotEnvironment.current.diffTool
    ///
    /// // Configuring a custom diff tool
    /// withTestingEnvironment {
    ///     $0.diffTool = .ksdiff
    /// } operation: {
    ///     // Your testing code here
    /// }
    /// ```
    ///
    /// - Note: The diff tool is only used when snapshot comparisons fail and a visual diff is needed.
    /// - SeeAlso:
    ///     - ``DiffTool``
    ///     - ``withTestingEnvironment(record:diffTool:maxConcurrentTests:platform:operation:file:line:)``
    public var diffTool: DiffTool {
        get { self[DiffToolEnvironmentKey.self] }
        set { self[DiffToolEnvironmentKey.self] = newValue }
    }
}
