#if canImport(SwiftSyntax509) && (os(macOS) || os(Linux) || os(Windows))
  import Foundation
  @_spi(Internals) import SnapshotTesting

  /// Asserts that a given piece of Swift source code emits certain diagnostics when compiled.
  ///
  /// The code is type-checked using a Swift compiler, and any diagnostics produced are rendered
  /// inline into the test file as a snapshot:
  ///
  /// ```swift
  /// assertCompilation {
  ///   """
  ///   let x = 1
  ///   let y = x + "!"
  ///   """
  /// } diagnostics: {
  ///   """
  ///   let y = x + "!"
  ///             ˄
  ///             ╰─ error: binary operator '+' cannot be applied to operands of type 'Int' and 'String'
  ///             ╰─ note: overloads for '+' exist with these partially matching parameter lists: (Int, Int), (String, String)
  ///   """
  /// }
  /// ```
  ///
  /// If the code compiles cleanly, no `diagnostics` closure is required.
  ///
  /// By default the code is compiled with the toolchain's default compiler (`xcrun swiftc` on
  /// Apple platforms, `swiftc` from the path elsewhere), but this is customizable, as are the
  /// flags passed to the compiler:
  ///
  /// ```swift
  /// assertCompilation(
  ///   compiler: .swiftly("6.2.0"),
  ///   flags: [.languageMode(.v5), "-warnings-as-errors"]
  /// ) {
  ///   """
  ///   // …
  ///   """
  /// }
  /// ```
  ///
  /// Both the compiler and flags can also be applied to entire scopes using the
  /// ``Testing/Trait/compilation(compiler:flags:)`` trait or the
  /// ``withCompilationTesting(compiler:flags:operation:)-1abcd`` function. A compiler passed here
  /// overrides any ambient compiler, while flags passed here are appended after any ambient
  /// flags.
  ///
  /// - Parameters:
  ///   - compiler: The Swift compiler to invoke. Defaults to any ambient compiler, or
  ///     ``SwiftCompiler/default``.
  ///   - flags: Additional flags to pass to the Swift compiler, _e.g._
  ///     `[.languageMode(.v6)]`, `[.strictConcurrency(.complete)]`, etc. Appended after any
  ///     ambient flags.
  ///   - message: An optional description of the assertion, for inclusion in test results.
  ///   - record: Whether or not to record a new reference.
  ///   - code: The Swift source code to compile.
  ///   - expected: An optional closure that returns a previously generated snapshot of the
  ///     compiler's diagnostics. When omitted, the library will automatically write a snapshot into
  ///     your test file at the call site of the assertion.
  ///   - fileID: The file ID in which failure occurred.
  ///   - filePath: The file in which failure occurred.
  ///   - function: The function where the assertion occurs.
  ///   - line: The line number on which failure occurred.
  ///   - column: The column on which failure occurred.
  public func assertCompilation(
    compiler: SwiftCompiler? = nil,
    flags: [SwiftFlag] = [],
    message: @autoclosure () -> String = "",
    record: SnapshotTestingConfiguration.Record? = nil,
    of code: () -> String,
    diagnostics expected: (() -> String)? = nil,
    fileID: StaticString = #fileID,
    file filePath: StaticString = #filePath,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
  ) {
    let source = code()
    let configuration = CompilationTestingConfiguration.current
    let compiler = compiler ?? configuration?.compiler ?? .default
    let flags = ((configuration?.flags ?? []) + flags).flatMap(\.arguments)
    let actual: String?
    do {
      let diagnostics = try compile(source, compiler: compiler, flags: flags)
      actual = diagnostics.isEmpty ? nil : render(diagnostics: diagnostics, in: source)
    } catch {
      recordIssue(
        "Failed to invoke the Swift compiler: \(error)",
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
      return
    }
    guard actual != nil || expected != nil
    else { return }
    assertInlineSnapshot(
      of: actual,
      as: .lines,
      message: message(),
      record: record,
      syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
        trailingClosureLabel: "diagnostics",
        trailingClosureOffset: 1
      ),
      matches: expected,
      fileID: fileID,
      file: filePath,
      function: function,
      line: line,
      column: column
    )
  }

  /// A description of how to invoke a Swift compiler.
  ///
  /// A compiler is described by the executable to launch, arguments to insert before any flags and
  /// the source path, and an optional environment. Several common invocations come with the
  /// library:
  ///
  ///   * ``default``: `xcrun swiftc` on Apple platforms, `swiftc` from the path elsewhere.
  ///   * ``xcrun``: The active Xcode toolchain's compiler (Apple platforms).
  ///   * ``swiftly(_:)``: A [swiftly](https://www.swift.org/swiftly)-managed toolchain, _e.g._
  ///     `.swiftly("6.2.0")` (Apple platforms and Linux).
  ///   * ``path(_:)``: An explicit path to a `swiftc` executable.
  ///
  /// Because this is an ordinary struct, invocations the library does not ship with can be
  /// described directly:
  ///
  /// ```swift
  /// let vendored = SwiftCompiler(
  ///   executable: URL(fileURLWithPath: "/opt/swift-dev/usr/bin/swiftc")
  /// )
  /// ```
  public struct SwiftCompiler: Sendable {
    /// The executable to launch.
    public var executable: URL

    /// Arguments inserted before any flags and the source path, _e.g._ `["swiftc"]` when
    /// `executable` is `xcrun`.
    public var arguments: [String]

    /// The environment for the compiler process, or `nil` to inherit the test process's
    /// environment.
    public var environment: [String: String]?

    /// The SDK to compile against, or `nil` to use the compiler's default.
    ///
    /// A compiler can only read `.swiftinterface` files produced by compilers up to its own
    /// version, so a toolchain older than the default SDK must be paired with an SDK from its own
    /// era, _e.g._:
    ///
    /// ```swift
    /// .swiftly(
    ///   "6.2.0",
    ///   sdk: URL(fileURLWithPath: """
    ///     /Applications/Xcode-26.2.0.app/Contents/Developer/Platforms/MacOSX.platform\
    ///     /Developer/SDKs/MacOSX.sdk
    ///     """)
    /// )
    /// ```
    public var sdk: URL?

    /// Initializes a compiler invocation.
    ///
    /// - Parameters:
    ///   - executable: The executable to launch.
    ///   - arguments: Arguments inserted before any flags and the source path.
    ///   - environment: The environment for the compiler process, or `nil` to inherit the test
    ///     process's environment.
    ///   - sdk: The SDK to compile against, or `nil` to use the compiler's default.
    public init(
      executable: URL,
      arguments: [String] = [],
      environment: [String: String]? = nil,
      sdk: URL? = nil
    ) {
      self.executable = executable
      self.arguments = arguments
      self.environment = environment
      self.sdk = sdk
    }

    /// The default compiler for the current platform: `xcrun swiftc` on Apple platforms, and
    /// `swiftc` found in the process's path elsewhere.
    ///
    /// If the `SWIFT_EXEC` environment variable is set, it is used instead.
    public static var `default`: Self {
      if let swiftExec = ProcessInfo.processInfo.environment["SWIFT_EXEC"] {
        return Self(executable: URL(fileURLWithPath: swiftExec))
      }
      #if os(macOS)
        return .xcrun
      #else
        return Self(
          executable: findExecutable("swiftc")
            ?? URL(fileURLWithPath: "swiftc")
        )
      #endif
    }

    #if os(macOS)
      /// The active Xcode toolchain's compiler, via `xcrun swiftc`.
      public static let xcrun = Self(
        executable: URL(fileURLWithPath: "/usr/bin/xcrun"),
        arguments: ["swiftc"]
      )
    #endif

    #if os(macOS) || os(Linux)
      /// A [swiftly](https://www.swift.org/swiftly)-managed toolchain's compiler.
      ///
      /// - Parameters:
      ///   - version: A version selector understood by swiftly, _e.g._ `"6.2.0"`,
      ///     `"main-snapshot"`, `"latest"`.
      ///   - sdk: The SDK to compile against, or `nil` to use the compiler's default. See
      ///     ``sdk`` for when a toolchain must pin an SDK.
      public static func swiftly(_ version: String, sdk: URL? = nil) -> Self {
        Self(
          executable: findExecutable("swiftly")
            ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".swiftly")
            .appendingPathComponent("bin")
            .appendingPathComponent("swiftly"),
          arguments: ["run", "swiftc", "+\(version)"],
          sdk: sdk
        )
      }
    #endif

    /// A compiler at an explicit path.
    ///
    /// - Parameters:
    ///   - url: The path to a `swiftc` executable.
    ///   - sdk: The SDK to compile against, or `nil` to use the compiler's default. See ``sdk``
    ///     for when a toolchain must pin an SDK.
    public static func path(_ url: URL, sdk: URL? = nil) -> Self {
      Self(executable: url, sdk: sdk)
    }
  }

  // MARK: - Private

  private func findExecutable(_ name: String) -> URL? {
    #if os(Windows)
      let name = name.hasSuffix(".exe") ? name : "\(name).exe"
      let pathVariable = "Path"
      let pathSeparator: Character = ";"
    #else
      let pathVariable = "PATH"
      let pathSeparator: Character = ":"
    #endif
    for searchPath in (ProcessInfo.processInfo.environment[pathVariable] ?? "")
      .split(separator: pathSeparator)
    {
      let candidate = URL(fileURLWithPath: String(searchPath)).appendingPathComponent(name)
      if FileManager.default.isExecutableFile(atPath: candidate.path) {
        return candidate
      }
    }
    return nil
  }

  private struct CompilerDiagnostic {
    var line: Int
    var column: Int
    var severity: String
    var message: String
  }

  private struct CompilerError: Error, CustomStringConvertible {
    var description: String
  }

  private func compile(
    _ source: String,
    compiler: SwiftCompiler,
    flags: [String]
  ) throws -> [CompilerDiagnostic] {
    let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent("swift-snapshot-testing")
      .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(
      at: temporaryDirectory, withIntermediateDirectories: true
    )
    defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
    // NB: Naming the file "main.swift" allows top-level statements.
    let sourceURL = temporaryDirectory.appendingPathComponent("main.swift")
    try source.write(to: sourceURL, atomically: true, encoding: .utf8)

    let process = Process()
    process.executableURL = compiler.executable
    // NB: Flags the library depends on come after the caller's so that they always win.
    //
    // NB: '-emit-sil' (rather than '-typecheck') runs the compiler's mandatory SIL passes, which
    //     produce diagnostics type checking alone does not: region isolation ('sending'), definite
    //     initialization, noncopyable consume checking, etc. The SIL output itself is discarded.
    process.arguments =
      compiler.arguments
      + (compiler.sdk.map { ["-sdk", $0.path] } ?? [])
      + flags
      + [
        "-emit-sil",
        "-o", temporaryDirectory.appendingPathComponent("main.sil").path,
        "-diagnostic-style", "llvm",
        sourceURL.path,
      ]
    if let environment = compiler.environment {
      process.environment = environment
    }
    process.currentDirectoryURL = temporaryDirectory
    let standardError = Pipe()
    process.standardOutput = Pipe()
    process.standardError = standardError
    try process.run()
    let outputData = standardError.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    let output = String(decoding: outputData, as: UTF8.self)

    var diagnostics: [CompilerDiagnostic] = []
    for outputLine in output.split(separator: "\n", omittingEmptySubsequences: true) {
      // NB: Diagnostics take the form "<path>:<line>:<column>: <severity>: <message>". Other
      //     lines (source echoes, caret markers, fix-its) are ignored.
      let components = outputLine.split(
        separator: ":", maxSplits: 4, omittingEmptySubsequences: false
      )
      guard
        components.count == 5,
        let line = Int(components[1]),
        let column = Int(components[2]),
        case let severity = components[3].trimmingCharacters(in: .whitespaces),
        ["error", "warning", "note", "remark"].contains(severity)
      else { continue }
      diagnostics.append(
        CompilerDiagnostic(
          line: line,
          column: column,
          severity: severity,
          message: components[4].trimmingCharacters(in: .whitespaces)
        )
      )
    }
    guard !diagnostics.isEmpty || process.terminationStatus == 0
    else {
      throw CompilerError(
        description: """
          '\(compiler.executable.lastPathComponent)' exited with code \
          \(process.terminationStatus): …

          \(output)
          """
      )
    }
    return diagnostics
  }

  private func render(diagnostics: [CompilerDiagnostic], in source: String) -> String {
    let sourceLines = source.components(separatedBy: "\n")
    var groups: [(line: Int, column: Int, diagnostics: [CompilerDiagnostic])] = []
    for diagnostic in diagnostics {
      if let index = groups.firstIndex(
        where: { $0.line == diagnostic.line && $0.column == diagnostic.column }
      ) {
        groups[index].diagnostics.append(diagnostic)
      } else {
        groups.append((diagnostic.line, diagnostic.column, [diagnostic]))
      }
    }

    var renderedLines: [String] = []
    for group in groups {
      let sourceLine =
        group.line - 1 < sourceLines.count && group.line > 0
        ? sourceLines[group.line - 1]
        : ""
      let indent = String(sourceLine.prefix(max(0, group.column - 1)).map { $0 == "\t" ? $0 : " " })
      renderedLines.append(sourceLine)
      renderedLines.append("\(indent)˄")
      for diagnostic in group.diagnostics {
        renderedLines.append("\(indent)╰─ \(diagnostic.severity): \(diagnostic.message)")
      }
    }
    return renderedLines.joined(separator: "\n")
  }
#endif
