#if canImport(SwiftSyntax509) && (os(macOS) || os(Linux) || os(Windows))
  /// Customizes `assertCompilation` for the duration of an operation.
  ///
  /// Use this operation to customize how the `assertCompilation` function behaves in a test. It is
  /// most convenient to use in the context of XCTest where you can wrap `invokeTest` of an
  /// `XCTestCase` subclass so that the configuration applies to every test method.
  ///
  /// > Note: To customize tests when using Swift's native Testing library, use the
  /// > ``Testing/Trait/compilation(compiler:flags:)`` trait.
  ///
  /// For example, to compile every assertion in a test class with a particular toolchain and
  /// language mode:
  ///
  /// ```swift
  /// class FeatureTests: XCTestCase {
  ///   override func invokeTest() {
  ///     withCompilationTesting(compiler: .swiftly("6.2.0"), flags: ["-swift-version", "6"]) {
  ///       super.invokeTest()
  ///     }
  ///   }
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
  ///   - operation: The operation to perform.
  public func withCompilationTesting<R>(
    compiler: SwiftCompiler? = nil,
    flags: [SwiftFlag]? = nil,
    building: [String]? = nil,
    operation: () throws -> R
  ) rethrows -> R {
    try CompilationTestingConfiguration.$current.withValue(
      CompilationTestingConfiguration(
        compiler: compiler ?? CompilationTestingConfiguration.current?.compiler,
        flags: (CompilationTestingConfiguration.current?.flags ?? []) + (flags ?? []),
        building: (CompilationTestingConfiguration.current?.building ?? []) + (building ?? [])
      )
    ) {
      try operation()
    }
  }

  /// Customizes `assertCompilation` for the duration of an asynchronous operation.
  ///
  /// See ``withCompilationTesting(compiler:flags:operation:)-1abcd`` for more information.
  public func withCompilationTesting<R>(
    compiler: SwiftCompiler? = nil,
    flags: [SwiftFlag]? = nil,
    building: [String]? = nil,
    operation: () async throws -> R
  ) async rethrows -> R {
    try await CompilationTestingConfiguration.$current.withValue(
      CompilationTestingConfiguration(
        compiler: compiler ?? CompilationTestingConfiguration.current?.compiler,
        flags: (CompilationTestingConfiguration.current?.flags ?? []) + (flags ?? []),
        building: (CompilationTestingConfiguration.current?.building ?? []) + (building ?? [])
      )
    ) {
      try await operation()
    }
  }

  /// The configuration for a compilation test.
  public struct CompilationTestingConfiguration: Sendable {
    @TaskLocal static var current: Self?

    /// The Swift compiler to invoke.
    public var compiler: SwiftCompiler?

    /// Flags to pass to the Swift compiler.
    public var flags: [SwiftFlag]?

    /// Targets of the package under test to build with the compiler's toolchain, making their
    /// modules importable.
    public var building: [String]?

    public init(
      compiler: SwiftCompiler? = nil,
      flags: [SwiftFlag]? = nil,
      building: [String]? = nil
    ) {
      self.compiler = compiler
      self.flags = flags
      self.building = building
    }
  }
#endif
