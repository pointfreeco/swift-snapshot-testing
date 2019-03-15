#if !os(Linux)
import XCTest

/// Enhances failure messages with a command line diff tool expression that can be copied and pasted into a terminal.
///
///     diffTool = "ksdiff"
public var diffTool: String? = nil

/// Whether or not to record all new references.
public var record = false

/// Simulators and devices to record snapshots for, or nil for pre-2.0 compatibility
public var supportedPlatforms: [Platform]? = nil

/// Asserts that a given value matches a reference on disk.
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - snapshotting: A strategy for serializing, deserializing, and comparing values.
///   - name: An optional description of the snapshot.
///   - recording: Whether or not to record a new reference.
///   - timeout: The amount of time a snapshot must be generated in.
///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
///   - testName: The name of the test in which failure occurred. Defaults to the function name of the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
public func assertSnapshot<Value, Format>(
  matching value: @autoclosure () throws -> Value,
  as snapshotting: Snapshotting<Value, Format>,
  named name: String? = nil,
  record recording: Bool = false,
  timeout: TimeInterval = 5,
  file: StaticString = #file,
  testName: String = #function,
  line: UInt = #line
  ) {

  let failure = verifySnapshot(
    matching: value,
    as: snapshotting,
    named: name,
    record: recording,
    timeout: timeout,
    file: file,
    testName: testName,
    line: line
  )
  guard let message = failure else { return }
  XCTFail(message, file: file, line: line)
}

/// Asserts that a given value matches references on disk.
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - snapshotting: An dictionnay of names and strategies for serializing, deserializing, and comparing values.
///   - recording: Whether or not to record a new reference.
///   - timeout: The amount of time a snapshot must be generated in.
///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
///   - testName: The name of the test in which failure occurred. Defaults to the function name of the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
public func assertSnapshots<Value, Format>(
  matching value: @autoclosure () throws -> Value,
  as strategies: [String: Snapshotting<Value, Format>],
  record recording: Bool = false,
  timeout: TimeInterval = 5,
  file: StaticString = #file,
  testName: String = #function,
  line: UInt = #line
  ) {

  strategies.forEach { name, strategy in
    assertSnapshot(
      matching: value,
      as: strategy,
      named: name,
      record: recording,
      timeout: timeout,
      file: file,
      testName: testName,
      line: line
    )
  }
}

/// Asserts that a given value matches references on disk.
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - snapshotting: An array of strategies for serializing, deserializing, and comparing values.
///   - recording: Whether or not to record a new reference.
///   - timeout: The amount of time a snapshot must be generated in.
///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
///   - testName: The name of the test in which failure occurred. Defaults to the function name of the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
public func assertSnapshots<Value, Format>(
  matching value: @autoclosure () throws -> Value,
  as strategies: [Snapshotting<Value, Format>],
  record recording: Bool = false,
  timeout: TimeInterval = 5,
  file: StaticString = #file,
  testName: String = #function,
  line: UInt = #line
  ) {

  strategies.forEach { strategy in
    assertSnapshot(
      matching: value,
      as: strategy,
      record: recording,
      timeout: timeout,
      file: file,
      testName: testName,
      line: line
    )
  }
}

/// Verifies that a given value matches a reference on disk.
///
/// Third party snapshot assert helpers can be built on top of this function. Simply invoke `verifySnapshot` with your own arguments, and then invoke `XCTFail` with the string returned if it is non-`nil`. For example, if you want the snapshot directory to be determined by an environment variable, you can create your own assert helper like so:
///
///     public func myAssertSnapshot<Value, Format>(
///       matching value: @autoclosure () throws -> Value,
///       as snapshotting: Snapshotting<Value, Format>,
///       named name: String? = nil,
///       record recording: Bool = false,
///       timeout: TimeInterval = 5,
///       file: StaticString = #file,
///       testName: String = #function,
///       line: UInt = #line
///       ) {
///
///         let snapshotDirectory = ProcessInfo.processInfo.environment["SNAPSHOT_REFERENCE_DIR"]! + "/" + #file
///         let failure = verifySnapshot(
///           matching: value,
///           as: snapshotting,
///           named: name,
///           record: recording,
///           snapshotDirectory: snapshotDirectory,
///           timeout: timeout,
///           file: file,
///           testName: testName
///         )
///         guard let message = failure else { return }
///         XCTFail(message, file: file, line: line)
///     }
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - snapshotting: A strategy for serializing, deserializing, and comparing values.
///   - name: An optional description of the snapshot.
///   - recording: Whether or not to record a new reference.
///   - snapshotDirectory: Optional directory to save snapshots. By default snapshots will be saved in a directory with the same name as the test file, and that directory will sit inside a directory `__Snapshots__` that sits next to your test file.
///   - timeout: The amount of time a snapshot must be generated in.
///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
///   - testName: The name of the test in which failure occurred. Defaults to the function name of the test case in which this function was called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
/// - Returns: A failure message or, if the value matches, nil.
public func verifySnapshot<Value, Format>(
  matching value: @autoclosure () throws -> Value,
  as snapshotting: Snapshotting<Value, Format>,
  named name: String? = nil,
  record recording: Bool = false,
  snapshotDirectory: String? = nil,
  timeout: TimeInterval = 5,
  file: StaticString = #file,
  testName: String = #function,
  line: UInt = #line
  )
  -> String? {

    let recording = recording || record

    do {
      let fileUrl = URL(fileURLWithPath: "\(file)")
      let fileName = fileUrl.deletingPathExtension().lastPathComponent

      let snapshotDirectoryUrl = snapshotDirectory.map(URL.init(fileURLWithPath:))
        ?? fileUrl
          .deletingLastPathComponent()
          .appendingPathComponent("__Snapshots__")
          .appendingPathComponent(fileName)

      let identifier: String
      if let name = name {
        identifier = sanitizePathComponent(name)
      } else {
        let counter = counterQueue.sync { () -> Int in
          let key = snapshotDirectoryUrl.appendingPathComponent(testName)
          counterMap[key, default: 0] += 1
          return counterMap[key]!
        }
        identifier = String(counter)
      }

      let platform = Platform()
      let testName = sanitizePathComponent(testName)
      let preV2Basename = "\(testName).\(identifier)"
      let postV2Basename = "\(testName)-\(identifier)-\(platform.rawValue)"
      let fileBasename: String = supportedPlatforms == nil ? preV2Basename : postV2Basename
      let snapshotFileUrl = snapshotDirectoryUrl
        .appendingPathComponent(fileBasename)
        .appendingPathExtension(snapshotting.pathExtension ?? "")
      let fileManager = FileManager.default
      try fileManager.createDirectory(at: snapshotDirectoryUrl, withIntermediateDirectories: true)

      let tookSnapshot = XCTestExpectation(description: "Took snapshot")
      var optionalDiffable: Format?
      snapshotting.snapshot(try value()).run { b in
        optionalDiffable = b
        tookSnapshot.fulfill()
      }
      let result = XCTWaiter.wait(for: [tookSnapshot], timeout: timeout)
      switch result {
      case .completed:
        break
      case .timedOut:
        return "Exceeded timeout of \(timeout) seconds waiting for snapshot"
      case .incorrectOrder, .invertedFulfillment, .interrupted:
        return "Couldn't snapshot value"
      }

      guard let diffable = optionalDiffable else {
        return "Couldn't snapshot value"
      }

      guard !recording, fileManager.fileExists(atPath: snapshotFileUrl.path) else {
        let diffMessage = (try? Data(contentsOf: snapshotFileUrl))
          .flatMap { data in snapshotting.diffing.diff(snapshotting.diffing.fromData(data), diffable) }
          .map { diff, _ in diff.trimmingCharacters(in: .whitespacesAndNewlines) }
          ?? "Recorded snapshot: …"

        // FIXME: check for pre-v2 filename format which will no longer match
        
        if let supportedPlatforms = supportedPlatforms,
          !supportedPlatforms.contains(platform),
          let otherSnapshots = Optional.some(try fileManager.contentsOfDirectory(
            atPath: snapshotFileUrl.deletingLastPathComponent().path)),
          // FIXME: duplicated string-construction
          let snapshotFromOtherSimulator = otherSnapshots
            .first(where: { $0.starts(with: "\(testName)-\(identifier)-") }) {
          // Do *not* autorecord a screenshot, regardless of recording=true
          // FIXME: this reports only the filename, not full path, of the other snapshot
          return """
          A screenshot already exists from an incompatible simulator. To record from this simulator add "\(platform.rawValue)" to SnapshotTesting.supportedPlatforms.
          
          see "\(snapshotFromOtherSimulator)"
          """
        }
          
        try snapshotting.diffing.toData(diffable).write(to: snapshotFileUrl)
        return recording
          ? """
            Record mode is on. Turn record mode off and re-run "\(testName)" to test against the newly-recorded snapshot.

            open "\(snapshotFileUrl.path)"

            \(diffMessage)
            """
          : """
            No reference was found on disk. Automatically recorded snapshot: …

            open "\(snapshotFileUrl.path)"

            Re-run "\(testName)" to test against the newly-recorded snapshot.
            """
      }

      let data = try Data(contentsOf: snapshotFileUrl)
      let reference = snapshotting.diffing.fromData(data)

      guard let (failure, attachments) = snapshotting.diffing.diff(reference, diffable) else {
        return nil
      }

      let artifactsUrl = URL(
        fileURLWithPath: ProcessInfo.processInfo.environment["SNAPSHOT_ARTIFACTS"] ?? NSTemporaryDirectory()
      )
      let artifactsSubUrl = artifactsUrl.appendingPathComponent(fileName)
      try fileManager.createDirectory(at: artifactsSubUrl, withIntermediateDirectories: true)
      let failedSnapshotFileUrl = artifactsSubUrl.appendingPathComponent(snapshotFileUrl.lastPathComponent)
      try snapshotting.diffing.toData(diffable).write(to: failedSnapshotFileUrl)

      if !attachments.isEmpty {
        #if !os(Linux)
        if ProcessInfo.processInfo.environment.keys.contains("__XCODE_BUILT_PRODUCTS_DIR_PATHS") {
          XCTContext.runActivity(named: "Attached Failure Diff") { activity in
            attachments.forEach {
              activity.add($0)
            }
          }
        }
        #endif
      }

      let diffMessage = diffTool
        .map { "\($0) \"\(snapshotFileUrl.path)\" \"\(failedSnapshotFileUrl.path)\"" }
        ?? "@\(minus)\n\"\(snapshotFileUrl.path)\"\n@\(plus)\n\"\(failedSnapshotFileUrl.path)\""
      return """
      Snapshot does not match reference.

      \(diffMessage)

      \(failure.trimmingCharacters(in: .whitespacesAndNewlines))
      """
    } catch {
      return error.localizedDescription
    }
}

private let counterQueue = DispatchQueue(label: "co.pointfree.SnapshotTesting.counter")
private var counterMap: [URL: Int] = [:]
#endif

func sanitizePathComponent(_ string: String) -> String {
  return string
    .replacingOccurrences(of: "\\W+", with: "-", options: .regularExpression)
    .replacingOccurrences(of: "^-|-$", with: "", options: .regularExpression)
}

public struct Platform: Equatable {
  let os: OS
  let version: String
  let gamut: Gamut
  let scale: Int

  enum Gamut: String {
    case unspecified
    case SRGB = "srgb"
    case P3 = "p3"
    
    init(from gamut: UIDisplayGamut) {
      switch gamut {
      case .unspecified: self = .unspecified
      case .SRGB: self = .SRGB
      case .P3: self = .P3
      }
    }
  }
  
  enum OS: String {
    case iOS, macOS, tvOS, linux
    
    init() {
      #if os(iOS)
      self = .iOS
      #endif
      #if os(macOS)
      self = .macOS
      #endif
      #if os(tvOS)
      self = .tvOS
      #endif
      #if os(Linux)
      self = .linux
      #endif
    }
  }
}

extension Platform {
  internal init() {
    os = OS()
    version = ProcessInfo().operatingSystemVersion.pretty
    #if os(Linux)
    gamut = .unspecified
    scale = 0 // "unspecified" in UITraitCollection.displayScale
    #endif
    #if os(iOS) || os(tvOS)
    let traits = UIScreen.main.traitCollection
    gamut = Gamut(from: traits.displayGamut)
    scale = Int(traits.displayScale)
    #endif
    #if os(macOS)
    // TODO (no trait collection, gamut especially seems to have to read API?)
    #endif
  }
}

extension OperatingSystemVersion {
  fileprivate var pretty: String {
    return patchVersion == 0 ? "\(majorVersion).\(minorVersion)" : "\(majorVersion).\(minorVersion).\(patchVersion)"
  }
}

extension Platform: RawRepresentable {
  public var rawValue: String {
    return "\(os)-\(version)-\(gamut.rawValue)@\(scale)x"
  }
  
  public init?(rawValue: String) {
    let components = rawValue.split(separator: "-")
    guard components.count == 3 else { return nil }
    guard let os = OS(rawValue: String(components[0])) else { return nil }
    guard components[2].last == "x" else { return nil } // FIXME: oh come on this is ridiculous
    let imageStuff = components[2].dropLast().split(separator: "@")
    guard imageStuff.count == 2 else { return nil }
    guard let gamut = Gamut(rawValue: String(imageStuff[0])) else { return nil }
    guard let scale = Int(imageStuff[1]) else { return nil }
    self.os = os
    self.gamut = gamut
    self.version = String(components[1]) // FIXME: validate it's a version-string?
    self.scale = scale
  }
}

extension Platform {
  public static let iPhone5sSimulator_12_1 = Platform(os: .iOS, version: "12.1", gamut: .SRGB, scale: 2)
  public static let iPhoneXrSimulator_12_1 = Platform(os: .iOS, version: "12.1", gamut: .P3, scale: 2)
}
