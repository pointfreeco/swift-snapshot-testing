#if canImport(SwiftSyntax509) && (os(macOS) || os(Linux) || os(Windows))
  /// A flag to pass to the Swift compiler.
  ///
  /// A flag represents zero or more command line arguments, and comes with static constructors
  /// for common, testing-relevant compiler options, mirroring the vocabulary of SwiftPM's
  /// `SwiftSetting`:
  ///
  /// ```swift
  /// assertCompilation(
  ///   flags: [.languageMode(.v6), .defaultIsolation(.mainActor)]
  /// ) {
  ///   """
  ///   // …
  ///   """
  /// }
  /// ```
  ///
  /// A flag can also be expressed as a string literal, where each literal is a single command
  /// line argument, so untyped flags can be passed alongside typed ones:
  ///
  /// ```swift
  /// assertCompilation(
  ///   flags: [.languageMode(.v6), "-verify-additional-prefix", "expected-"]
  /// ) {
  ///   """
  ///   // …
  ///   """
  /// }
  /// ```
  ///
  /// And because this is an ordinary struct, flags the library does not ship with, or bundles of
  /// flags a project uses repeatedly, can be defined in an extension:
  ///
  /// ```swift
  /// extension SwiftFlag {
  ///   static let strictestConcurrency = Self(arguments: [
  ///     "-swift-version", "6",
  ///     "-strict-concurrency=complete",
  ///     "-enable-upcoming-feature", "ExistentialAny",
  ///   ])
  /// }
  /// ```
  public struct SwiftFlag: Sendable, ExpressibleByStringLiteral {
    /// The command line arguments this flag expands to.
    public var arguments: [String]

    /// Initializes a flag from command line arguments.
    ///
    /// - Parameter arguments: The command line arguments this flag expands to.
    public init(arguments: [String]) {
      self.arguments = arguments
    }

    /// Initializes a flag from a string literal representing a single command line argument.
    public init(stringLiteral value: String) {
      self.init(arguments: [value])
    }

    /// Compiles in a specific language mode, _e.g._ `-swift-version 6`.
    public static func languageMode(_ mode: LanguageMode) -> Self {
      Self(arguments: ["-swift-version", mode.rawValue])
    }

    /// Compiles with a default actor isolation, _e.g._ `-default-isolation MainActor`.
    public static func defaultIsolation(_ isolation: DefaultIsolation) -> Self {
      Self(arguments: ["-default-isolation", isolation.rawValue])
    }

    /// Enables an upcoming feature, _e.g._ `-enable-upcoming-feature ExistentialAny`.
    public static func enableUpcomingFeature(_ name: String) -> Self {
      Self(arguments: ["-enable-upcoming-feature", name])
    }

    /// Enables an experimental feature, _e.g._ `-enable-experimental-feature Embedded`.
    public static func enableExperimentalFeature(_ name: String) -> Self {
      Self(arguments: ["-enable-experimental-feature", name])
    }

    /// Compiles with a strict concurrency checking level, _e.g._
    /// `-strict-concurrency=complete`.
    public static func strictConcurrency(_ level: StrictConcurrency) -> Self {
      Self(arguments: ["-strict-concurrency=\(level.rawValue)"])
    }

    /// Defines a compilation condition, _e.g._ `-D DEBUG`.
    public static func define(_ name: String) -> Self {
      Self(arguments: ["-D", name])
    }

    /// Escalates all warnings to errors, _i.e._ `-warnings-as-errors`.
    public static let warningsAsErrors = Self(arguments: ["-warnings-as-errors"])

    /// Enables strict memory safety checking, _i.e._ `-strict-memory-safety`.
    public static let strictMemorySafety = Self(arguments: ["-strict-memory-safety"])

    /// A flag of arbitrary command line arguments.
    ///
    /// - Parameter arguments: The command line arguments this flag expands to.
    public static func custom(_ arguments: String...) -> Self {
      Self(arguments: arguments)
    }

    /// A Swift language mode, as passed to `-swift-version`.
    public struct LanguageMode: Sendable {
      public var rawValue: String
      public init(_ rawValue: String) {
        self.rawValue = rawValue
      }
      public static let v4 = Self("4")
      public static let v4_2 = Self("4.2")
      public static let v5 = Self("5")
      public static let v6 = Self("6")
    }

    /// A default actor isolation, as passed to `-default-isolation`.
    public struct DefaultIsolation: Sendable {
      public var rawValue: String
      public init(_ rawValue: String) {
        self.rawValue = rawValue
      }
      public static let mainActor = Self("MainActor")
      public static let nonisolated = Self("nonisolated")
    }

    /// A strict concurrency checking level, as passed to `-strict-concurrency`.
    public struct StrictConcurrency: Sendable {
      public var rawValue: String
      public init(_ rawValue: String) {
        self.rawValue = rawValue
      }
      public static let minimal = Self("minimal")
      public static let targeted = Self("targeted")
      public static let complete = Self("complete")
    }
  }
#endif
