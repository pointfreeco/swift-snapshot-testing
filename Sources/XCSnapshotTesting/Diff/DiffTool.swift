import Foundation

/// A formatter for generating snapshot comparison messages in the console or for use with external diff tools.
///
/// `DiffTool` provides a flexible way to format output displayed in the Xcode console when a snapshot comparison fails.
/// This output may consist of:
/// - Human-readable error messages (e.g., `.default`)
/// - Shell commands to launch external comparison tools (e.g., `.ksdiff` for Kaleidoscope)
///
/// The generated output is **not automatically executed** by the library. Developers or continuous integration systems
/// may process it manually, such as by copying and pasting commands into a terminal or automating with scripts.
///
/// ## Usage
/// You can use one of the built-in presets, such as `.default` or `.ksdiff`, or provide a custom formatter,
/// either as a closure or string literal. For example:
///
/// ```swift
/// let customTool: DiffTool = { ref, actual in
///     "diff \"\(ref)\" \"\(actual)\""
/// }
///
/// let literalTool: DiffTool = "open -a Kaleidoscope"
/// ```
///
/// To configure the diff tool for tests, use `withTestingEnvironment(diffTool: ...)` or specify it through Swift Testing traits.
///
/// ## Thread Safety
/// `DiffTool` is `Sendable` and safe to use from concurrent test runners.
///
/// ## Configuration via Swift Testing Traits
/// The diff tool can also be configured using Swift Testing traits, allowing you to set it at a project or target level
/// without modifying individual test files.
///
/// ## See Also
/// - ``withTestingEnvironment(record:diffTool:maxConcurrentTests:platform:operation:file:line:)``
/// - ``DiffTool/ksdiff``
/// - ``DiffTool/default``
///
/// - Note: The formatting closure is always given two absolute file paths: the reference (current/expected) file, and the failed (actual/current) file.
public struct DiffTool: Sendable, ExpressibleByStringLiteral {

    /// Formats output for [Kaleidoscope](http://kaleidoscope.app).
    ///
    /// Generates a shell command that can be executed externally to open Kaleidoscope,
    /// comparing the two file paths provided.
    ///
    /// - Example output:
    ///   ```bash
    ///   ksdiff "/path/reference-file.png" "/path/failed-file.png"
    ///   ```
    ///
    /// - WARNING: Requires Kaleidoscope to be installed and the `ksdiff` command-line tool to be available.
    /// - Parameters:
    ///   - currentFilePath: The path to the reference (expected) file.
    ///   - failedFilePath: The path to the failed (actual) file.
    /// - Returns: A shell command string that can be executed to launch Kaleidoscope for file comparison.
    public static let ksdiff = Self {
        "ksdiff \"\($0)\" \"\($1)\""
    }

    /// Default format (human-readable error in console).
    ///
    /// Generates a message guiding developers to configure an advanced diff tool for more interactive file comparison.
    ///
    /// - Output Example:
    ///   ```plaintext
    ///   @−
    ///   "/path/to/reference.png"
    ///   @+
    ///   "/path/to/failed.png"
    ///
    ///   To configure output for a custom diff tool, use 'withTestingEnvironment'. For example:
    ///
    ///       withTestingEnvironment(diffTool: .ksdiff) {
    ///         // ...
    ///       }
    ///   ```
    ///
    /// - Use Cases:
    ///   - Suitable for CI environments or when no external diff tool is available.
    ///   - Provides clear next steps for developers to configure more advanced comparison tools.
    /// - SeeAlso: ``DiffTool/ksdiff``, ``withTestingEnvironment(record:diffTool:maxConcurrentTests:platform:operation:file:line:)``
    public static let `default` = Self {
        """
        @−
        "\($0)"
        @+
        "\($1)"

        To configure output for a custom diff tool, use 'withTestingEnvironment'. For example:

            withTestingEnvironment(diffTool: .ksdiff) {
              // ...
            }
        """
    }

    private var tool: @Sendable (_ currentFilePath: String, _ failedFilePath: String) -> String

    /// Initializes a new `DiffTool` with a custom formatting closure.
    ///
    /// Use this initializer to define how snapshot difference output is generated. The closure receives the absolute
    /// file paths of the reference ("current") and failed ("actual") files, and returns a string that will be shown
    /// in the console or passed to external processes.
    ///
    /// Example usage:
    /// ```swift
    /// let customDiff = DiffTool { ref, actual in
    ///     "diff \"\(ref)\" \"\(actual)\""
    /// }
    /// ```
    ///
    /// - Parameter tool:
    ///   A closure that formats the output for failed snapshot comparisons.
    ///   - `currentFilePath`: The absolute path to the reference (expected) file.
    ///   - `failedFilePath`: The absolute path to the failed (actual) file.
    ///   - Returns: The formatted string to display or process.
    ///
    /// - Note: The closure must be `Sendable` to ensure thread safety during concurrent test execution.
    public init(
        _ tool: @escaping @Sendable (_ currentFilePath: String, _ failedFilePath: String) -> String
    ) {
        self.tool = tool
    }

    /// Initializes the tool from a string literal.
    ///
    /// - Parameter value: Text or command formatted with file paths. `$0` and `$1` are replaced by the reference and failed file paths, respectively. If `$0` or `$0` aren't provided, it'll be added at the end of string separated with space.
    ///
    /// - Example: `DiffTool("open -a Kaleidoscope $0 $1")` generates `open -a Kaleidoscope /path1 /path2`.
    ///
    /// - Note: The string is evaluated as a command to be executed externally. Ensure proper formatting for your shell or environment.
    public init(stringLiteral value: StringLiteralType) {
        self.tool = {
            if value.contains("$0") || value.contains("$1") {
                return
                    value
                    .replacingOccurrences(of: "$0", with: $0)
                    .replacingOccurrences(of: "$1", with: $1)
            } else {
                return "\(value) \($0) \($1)"
            }
        }
    }

    /// Generates the comparison output.
    ///
    /// - Parameters:
    ///   - currentFilePath: Path to the reference file.
    ///   - failedFilePath: Path to the compared file.
    /// - Returns: A string representing the formatted comparison output, which may include:
    ///   - Human-readable error messages (e.g., for `.default`)
    ///   - Shell commands for external diff tools (e.g., `.ksdiff`)
    ///   - Custom-format strings defined by the user
    ///
    /// - Note: The output is intended for display in the Xcode console or Terminal. It can be
    ///   manually executed or processed by scripts, but the library itself does not
    ///   execute the generated commands.
    public func callAsFunction(currentFilePath: String, failedFilePath: String) -> String {
        self.tool(currentFilePath, failedFilePath)
    }
}
