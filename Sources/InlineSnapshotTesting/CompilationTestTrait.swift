#if canImport(Testing) && canImport(SwiftSyntax509) && (os(macOS) || os(Linux) || os(Windows))
  import Testing

  /// A type representing the configuration of compilation testing.
  public struct _CompilationTestTrait: SuiteTrait, TestTrait {
    public let isRecursive = true
    let configuration: CompilationTestingConfiguration
  }

  extension Trait where Self == _CompilationTestTrait {
    /// Configure compilation testing in a suite or test.
    ///
    /// For example, to compile every assertion in a suite with a particular toolchain and
    /// language mode:
    ///
    /// ```swift
    /// @Suite(.compilation(compiler: .swiftly("6.2.0"), flags: ["-swift-version", "6"]))
    /// struct FeatureTests {
    ///   // ...
    /// }
    /// ```
    ///
    /// The compiler overrides any ambient compiler, while flags accumulate: flags passed here are
    /// appended after any already in scope, and flags passed to `assertCompilation` itself are
    /// appended after that. Because the compiler treats the last occurrence of most options as
    /// authoritative, more specific flags win.
    ///
    /// - Parameters:
    ///   - compiler: The Swift compiler to invoke.
    ///   - flags: Flags to pass to the Swift compiler, appended after any flags already in scope.
    public static func compilation(
      compiler: SwiftCompiler? = nil,
      flags: [SwiftFlag]? = nil,
      building: [String]? = nil
    ) -> Self {
      _CompilationTestTrait(
        configuration: CompilationTestingConfiguration(
          compiler: compiler,
          flags: flags,
          building: building
        )
      )
    }

    /// Configure compilation testing in a suite or test.
    ///
    /// - Parameter configuration: The configuration to use.
    public static func compilation(
      _ configuration: CompilationTestingConfiguration
    ) -> Self {
      _CompilationTestTrait(configuration: configuration)
    }
  }

  #if compiler(>=6.1)
    extension _CompilationTestTrait: TestScoping {
      public func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: () async throws -> Void
      ) async throws {
        try await withCompilationTesting(
          compiler: configuration.compiler,
          flags: configuration.flags
        ) {
          try await function()
        }
      }
    }
  #endif
#endif
