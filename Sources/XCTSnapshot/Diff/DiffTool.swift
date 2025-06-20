import Foundation

/// Defines formatters for snapshot comparison messages.
///
/// A `DiffTool` generates output (text) displayed in the Xcode console when a snapshot fails. This output can be:
/// - An instructional error message (`.default`).
/// - A Shell command for external tools (ex: `ksdiff` for Kaleidoscope).
///
/// - WARNING: The generated output **is not executed automatically** by the library. Developers or CI systems
/// may process it manually via scripts.
public struct DiffTool: Sendable, ExpressibleByStringLiteral {

  /// Formats output for [Kaleidoscope](http://kaleidoscope.app).
  ///
  /// Generates a Shell command that, when executed externally, opens Kaleidoscope to compare files.
  ///
  /// - Example output:
  ///   ```bash
  ///   ksdiff "/path/reference-file.png" "/path/failed-file.png"
  ///   ```
  ///
  /// - WARNING: Requires Kaleidoscope to be installed.
  public static let ksdiff = Self {
    "ksdiff \"\($0)\" \"\($1)\""
  }

  /// Default format (human-readable error in console).
  ///
  /// Generates a message guiding developers to configure an advanced diff tool:
  ///
  /// ```plaintext
  /// ⚠️ Difference detected
  ///
  /// @-
  /// "file://\($0)"
  /// @+
  /// "file://\($1)"
  ///
  /// To configure a tool-specific output, use 'withTestingEnvironment'. Example:
  ///
  ///     withTestingEnvironment(diffTool: .ksdiff) {
  ///         // ...
  ///     }
  /// ```
  ///
  /// - Note: Useful in environments where automatic command execution is not possible (ex: CI).
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

  /// Initializes a custom formatter.
  ///
  /// - Parameter tool: Function generating output (text) from file paths.
  ///   - `currentFilePath`: Path to the reference file.
  ///   - `failedFilePath`: Path to the compared file.
  ///   - Returns: String displayed in console or processed externally.
  ///
  /// - Example:
  ///   ```swift
  ///   DiffTool { current, failed in
  ///       "diff $current $failed"
  ///   }
  ///   ```
  public init(
    _ tool: @escaping @Sendable (_ currentFilePath: String, _ failedFilePath: String) -> String
  ) {
    self.tool = tool
  }

  /// Initializes the tool from a string literal.
  ///
  /// - Parameter value: Text or command formatted with file paths.
  ///
  /// - Example: `DiffTool("open -a Kaleidoscope $0 $1")` generates `open -a Kaleidoscope /path1 /path2`.
  public init(stringLiteral value: StringLiteralType) {
    self.tool = { "\(value) \($0) \($1)" }
  }

  /// Generates the comparison output.
  ///
  /// - Parameter currentFilePath: Path to the reference file.
  /// - Parameter failedFilePath: Path to the compared file.
  /// - Returns:
  ///   - If using `.default`: Instructional error message.
  ///   - If using `.ksdiff`: Command to launch Kaleidoscope.
  ///   - If using custom string/tool: Custom-defined text.
  ///
  /// - NOTE: Output appears directly in the Xcode console or Terminal and can be copied for manual execution.
  public func callAsFunction(currentFilePath: String, failedFilePath: String) -> String {
    self.tool(currentFilePath, failedFilePath)
  }
}
