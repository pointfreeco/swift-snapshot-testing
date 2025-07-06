@_spi(Internals) import XCSnapshotTesting

/// A structure that describes the location of an inline snapshot.
///
/// Provide this structure when defining custom snapshot functions that call
/// ``InlineSnapshotTesting/assertInline(of:as:message:record:timeout:name:serialization:closureDescriptor:matches:fileID:file:function:line:column:)``
/// under the hood.
/// A descriptor for the trailing closure used to supply an inline snapshot in a custom snapshot assertion.
///
/// Use this type when implementing custom snapshot assertion utilities that ultimately delegate to
/// ``InlineSnapshotTesting/assertInline(of:as:message:record:timeout:name:serialization:closureDescriptor:matches:fileID:file:function:line:column:)``.
/// It describes the structure of the inline snapshot trailing closure, supporting both current and deprecated closure labels,
/// as well as more advanced cases where multiple trailing closures may exist.
///
/// This type enables tools and assertion infrastructure to accurately associate test failures or snapshot updates
/// with the correct closure in the source code, even in the presence of multiple or labeled trailing closures.
///
/// For example:
/// - A function with a single trailing closure for the snapshot uses the default offset (0) and label ("matches").
/// - A function with an additional preceding trailing closure requires a higher offset and possibly a custom label.
///
/// Deprecated closure labels are supported for migration scenarios, allowing detection and management of legacy call sites.
///
/// The type is `Sendable` and `Hashable`, making it suitable for concurrent and collection-based use.
public struct SnapshotClosureDescriptor: Sendable, Hashable {

    /// The default label describing an inline snapshot.
    public static let defaultTrailingClosureLabel = "matches"

    /// A list of trailing closure labels from deprecated interfaces.
    ///
    /// Useful for providing migration paths for custom snapshot functions.
    public var deprecatedTrailingClosureLabels: [String]

    /// The label of the trailing closure that returns the inline snapshot.
    public var trailingClosureLabel: String

    /// The offset of the trailing closure that returns the inline snapshot, relative to the first
    /// trailing closure.
    ///
    /// For example, a helper function with a few parameters and a single trailing closure has a
    /// trailing closure offset of 0:
    ///
    /// ```swift
    /// customInlineSnapshot(of: value, "Should match") {
    ///   // Inline snapshot...
    /// }
    /// ```
    ///
    /// While a helper function with a trailing closure preceding the snapshot closure has an offset
    /// of 1:
    ///
    /// ```swift
    /// customInlineSnapshot("Should match") {
    ///   // Some other parameter...
    /// } matches: {
    ///   // Inline snapshot...
    /// }
    /// ```
    public var trailingClosureOffset: Int

    /// Initializes an inline snapshot syntax descriptor.
    ///
    /// - Parameters:
    ///   - deprecatedTrailingClosureLabels: An array of deprecated labels to consider for the inline
    ///     snapshot.
    ///   - trailingClosureLabel: The label of the trailing closure that returns the inline snapshot.
    ///   - trailingClosureOffset: The offset of the trailing closure that returns the inline
    ///     snapshot, relative to the first trailing closure.
    public init(
        deprecatedTrailingClosureLabels: [String] = [],
        trailingClosureLabel: String = Self.defaultTrailingClosureLabel,
        trailingClosureOffset: Int = 0
    ) {
        self.deprecatedTrailingClosureLabels = deprecatedTrailingClosureLabels
        self.trailingClosureLabel = trailingClosureLabel
        self.trailingClosureOffset = trailingClosureOffset
    }

    #if canImport(SwiftSyntax601)
    /// Generates a test failure immediately and unconditionally at the described trailing closure.
    ///
    /// This method will attempt to locate the line of the trailing closure described by this type
    /// and call `XCTFail` with it. If the trailing closure cannot be located, the failure will be
    /// associated with the given line, instead.
    ///
    /// - Parameters:
    ///   - message: An optional description of the assertion, for inclusion in test results.
    ///   - fileID: The file ID in which failure occurred. Defaults to the file ID of the test case
    ///     in which this function was called.
    ///   - filePath: The file in which failure occurred. Defaults to the file path of the test case in
    ///     which this function was called.
    ///   - line: The line number on which failure occurred. Defaults to the line number on which
    ///     this function was called.
    ///   - column: The column on which failure occurred. Defaults to the column on which this
    ///     function was called.
    public func fail(
        _ message: @autoclosure () -> String,
        fileID: StaticString,
        file filePath: StaticString,
        line: UInt,
        column: UInt
    ) throws {
        var trailingClosureLine: Int?
        if let testSource = InlineSnapshotManager.current[SnapshotURL(path: filePath)] {
            let visitor = SnapshotVisitor(
                functionCallLine: Int(line),
                functionCallColumn: Int(column),
                sourceLocationConverter: testSource.sourceLocationConverter,
                closureDescriptor: self
            )
            visitor.walk(testSource.sourceFile)
            trailingClosureLine = visitor.trailingClosureLine
        }

        try TestingSystem.shared.record(
            message: message(),
            fileID: fileID,
            filePath: filePath,
            line: trailingClosureLine.map(UInt.init) ?? line,
            column: column
        )
    }

    func contains(_ label: String) -> Bool {
        self.trailingClosureLabel == label || self.deprecatedTrailingClosureLabels.contains(label)
    }
    #else
    @available(*, unavailable, message: "'assertInline' requires 'swift-syntax' >= 509.0.0")
    public func fail(
        _ message: @autoclosure () -> String = "",
        fileID: StaticString,
        file filePath: StaticString,
        line: UInt,
        column: UInt
    ) {
        fatalError()
    }
    #endif
}
