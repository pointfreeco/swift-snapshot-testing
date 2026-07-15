#!/usr/bin/swift
//
// snapshot-simulators: resolve snapshot platform strings to installed simulators.
//
// SnapshotTesting embeds the platform a snapshot was recorded on in its filename
// (e.g. "testFoo-1-iOS-18.5-p3@3x.png" — see Sources/SnapshotTesting/Platform.swift).
// Given such platform strings (or __Snapshots__ directories to scan for them), this
// script prints the installed simulators that render identically — i.e. that can
// verify or re-record those snapshots — or explains why none can.
//
// Usage:
//   scripts/snapshot-simulators.swift [--json] <platform-string> ...
//   scripts/snapshot-simulators.swift [--json] --snapshots <directory> ...
//
// Exit status: 0 if every requested platform has at least one match (or runs on the
// host rather than a simulator), 1 if any platform is unresolved, 64 on usage errors.
//
// OS version and display scale come from live CoreSimulator metadata (`simctl list`
// and each device type's profile.plist); display gamut is exposed by no metadata, so
// it is maintained in the table below.
// KEEP IN SYNC with Platform.knownSimulatedDevices in
// Sources/SnapshotTesting/Platform+Devices.swift.
//
// This script intentionally duplicates a small amount of the SnapshotTesting library
// (the platform-string parser and the gamut table). Its intended future home is an
// SPM executable target that imports the library and shares both; that is blocked
// today because the library target does not build for macOS (pre-existing
// NSBezierPath breakage under recent Swift) and the package tools-version is 5.0.

import Foundation

// MARK: - Pure logic (parsing, matching) — no I/O below this line until "Metadata loading"

struct PlatformSpec: Equatable {
  let os: String      // "iOS" | "macOS" | "tvOS" | "linux"
  let version: String // normalized, e.g. "18.5", "26.3.1"
  let gamut: String   // "unspecified" | "srgb" | "p3"
  let scale: Int

  var rawValue: String { return "\(os)-\(version)-\(gamut)@\(scale)x" }
}

let osCases = ["iOS", "macOS", "tvOS", "watchOS", "visionOS", "linux", "android", "windows", "unknown"]
let gamutCases = ["unspecified", "srgb", "p3"]

/// Trailing zero components beyond major.minor are insignificant: "18.5.0" == "18.5".
/// Mirrors Platform.normalize(version:) in the library.
func normalize(version: String) -> String {
  var components = version.split(separator: ".").map(String.init)
  while components.count > 2, components.last == "0" { components.removeLast() }
  while components.count < 2 { components.append("0") }
  return components.joined(separator: ".")
}

let platformPattern = try! NSRegularExpression(
  pattern: "(\(osCases.joined(separator: "|")))-([0-9]+(?:\\.[0-9]+){0,2})-(\(gamutCases.joined(separator: "|")))@([0-9]+)x"
)

func parsePlatform(_ string: String) -> PlatformSpec? {
  let fullRange = NSRange(string.startIndex..., in: string)
  guard
    let match = platformPattern.firstMatch(in: string, range: fullRange),
    match.range == fullRange
    else { return nil }
  func group(_ i: Int) -> String { return String(string[Range(match.range(at: i), in: string)!]) }
  guard let scale = Int(group(4)) else { return nil }
  return PlatformSpec(os: group(1), version: normalize(version: group(2)), gamut: group(3), scale: scale)
}

/// Extracts the platform suffix from a snapshot filename like
/// "testFoo-1-iOS-18.5-p3@3x.png". Anchored to the end of the basename because test
/// names and identifiers may themselves contain "-".
let filenamePattern = try! NSRegularExpression(
  pattern: "-((\(osCases.joined(separator: "|")))-[0-9]+(?:\\.[0-9]+){0,2}-(\(gamutCases.joined(separator: "|")))@[0-9]+x)\\.[^.]+$"
)

func platformString(ofSnapshotFileNamed fileName: String) -> String? {
  let fullRange = NSRange(fileName.startIndex..., in: fileName)
  guard let match = filenamePattern.firstMatch(in: fileName, range: fullRange) else { return nil }
  return String(fileName[Range(match.range(at: 1), in: fileName)!])
}

/// Display gamut per simulator model identifier.
/// KEEP IN SYNC with Platform.knownSimulatedDevices (Platform+Devices.swift).
let gamutByModelIdentifier: [String: String] = [
  // sRGB: pre-2016 devices, iPod touch, and base-model iPads through iPad (A16)
  "iPhone8,1": "srgb", "iPhone8,2": "srgb", "iPhone8,4": "srgb", "iPod9,1": "srgb",
  "iPad5,1": "srgb", "iPad5,4": "srgb", "iPad6,8": "srgb", "iPad6,12": "srgb",
  "iPad7,6": "srgb", "iPad7,12": "srgb", "iPad11,7": "srgb", "iPad12,2": "srgb",
  "iPad13,18": "srgb", "iPad15,7": "srgb",
  // P3: iPhone 7 and later
  "iPhone9,1": "p3", "iPhone9,2": "p3", "iPhone10,4": "p3", "iPhone10,5": "p3",
  "iPhone10,6": "p3", "iPhone11,2": "p3", "iPhone11,4": "p3", "iPhone11,8": "p3",
  "iPhone12,1": "p3", "iPhone12,3": "p3", "iPhone12,5": "p3", "iPhone12,8": "p3",
  "iPhone13,1": "p3", "iPhone13,2": "p3", "iPhone13,3": "p3", "iPhone13,4": "p3",
  "iPhone14,2": "p3", "iPhone14,3": "p3", "iPhone14,4": "p3", "iPhone14,5": "p3",
  "iPhone14,6": "p3", "iPhone14,7": "p3", "iPhone14,8": "p3",
  "iPhone15,2": "p3", "iPhone15,3": "p3", "iPhone15,4": "p3", "iPhone15,5": "p3",
  "iPhone16,1": "p3", "iPhone16,2": "p3",
  "iPhone17,1": "p3", "iPhone17,2": "p3", "iPhone17,3": "p3", "iPhone17,4": "p3", "iPhone17,5": "p3",
  "iPhone18,1": "p3", "iPhone18,2": "p3", "iPhone18,3": "p3", "iPhone18,4": "p3", "iPhone18,5": "p3",
  // P3: iPad Pro (from the 9.7-inch), iPad Air (from the 3rd gen), iPad mini (from the 5th gen)
  "iPad6,4": "p3", "iPad7,1": "p3", "iPad7,3": "p3",
  "iPad8,1": "p3", "iPad8,5": "p3", "iPad8,9": "p3", "iPad8,12": "p3",
  "iPad11,1": "p3", "iPad11,3": "p3", "iPad13,2": "p3", "iPad13,5": "p3",
  "iPad13,10": "p3", "iPad13,17": "p3", "iPad14,1": "p3", "iPad14,3": "p3",
  "iPad14,4": "p3", "iPad14,5": "p3", "iPad14,9": "p3", "iPad14,11": "p3",
  "iPad15,3": "p3", "iPad15,5": "p3", "iPad16,2": "p3", "iPad16,4": "p3",
  "iPad16,6": "p3", "iPad16,9": "p3", "iPad16,11": "p3",
  "iPad17,2": "p3", "iPad17,4": "p3",
  // Apple TV: unverified — see Platform+Devices.swift
  "AppleTV5,3": "unspecified", "AppleTV6,2": "unspecified",
  "AppleTV11,1": "unspecified", "AppleTV14,1": "unspecified",
]

// MARK: - Metadata loading

func run(_ arguments: [String]) -> Data {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
  process.arguments = arguments
  let pipe = Pipe()
  process.standardOutput = pipe
  try! process.run()
  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  process.waitUntilExit()
  guard process.terminationStatus == 0 else {
    FileHandle.standardError.write("error: xcrun \(arguments.joined(separator: " ")) failed\n".data(using: .utf8)!)
    exit(1)
  }
  return data
}

func simctlList(_ what: String) -> [String: Any] {
  let data = run(["simctl", "list", "-j", what])
  return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
}

struct DeviceType {
  let identifier: String
  let name: String
  let modelIdentifier: String?
  let scale: Int?
}

struct Runtime {
  let identifier: String  // com.apple.CoreSimulator.SimRuntime.iOS-18-5
  let os: String          // "iOS" | "tvOS" | ...
  let version: String     // normalized
  let name: String        // "iOS 18.5"
  let supportedDeviceTypes: [DeviceType]
}

struct Device {
  let name: String
  let udid: String
  let deviceTypeIdentifier: String
}

func loadDeviceType(fromBundlePath bundlePath: String, identifier: String, name: String) -> DeviceType {
  let profilePath = bundlePath + "/Contents/Resources/profile.plist"
  guard
    let data = FileManager.default.contents(atPath: profilePath),
    let profile = (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any]
    else { return DeviceType(identifier: identifier, name: name, modelIdentifier: nil, scale: nil) }
  let scale = (profile["mainScreenScale"] as? NSNumber).map { Int(truncating: $0) }
  return DeviceType(
    identifier: identifier,
    name: name,
    modelIdentifier: profile["modelIdentifier"] as? String,
    scale: scale
  )
}

func loadRuntimes() -> [Runtime] {
  let list = simctlList("runtimes")["runtimes"] as? [[String: Any]] ?? []
  return list.compactMap { runtime in
    guard
      runtime["isAvailable"] as? Bool == true,
      let identifier = runtime["identifier"] as? String,
      let version = runtime["version"] as? String,
      let name = runtime["name"] as? String
      else { return nil }
    // "com.apple.CoreSimulator.SimRuntime.iOS-18-5" -> "iOS"
    let os = identifier
      .replacingOccurrences(of: "com.apple.CoreSimulator.SimRuntime.", with: "")
      .split(separator: "-").first.map(String.init) ?? ""
    let deviceTypes = (runtime["supportedDeviceTypes"] as? [[String: Any]] ?? []).compactMap {
      type -> DeviceType? in
      guard
        let bundlePath = type["bundlePath"] as? String,
        let typeIdentifier = type["identifier"] as? String,
        let typeName = type["name"] as? String
        else { return nil }
      return loadDeviceType(fromBundlePath: bundlePath, identifier: typeIdentifier, name: typeName)
    }
    return Runtime(
      identifier: identifier, os: os, version: normalize(version: version), name: name,
      supportedDeviceTypes: deviceTypes)
  }
}

func loadDevices() -> [String: [Device]] {
  let byRuntime = simctlList("devices")["devices"] as? [String: [[String: Any]]] ?? [:]
  return byRuntime.mapValues { devices in
    devices.compactMap { device in
      guard
        device["isAvailable"] as? Bool == true,
        let name = device["name"] as? String,
        let udid = device["udid"] as? String,
        let typeIdentifier = device["deviceTypeIdentifier"] as? String
        else { return nil }
      return Device(name: name, udid: udid, deviceTypeIdentifier: typeIdentifier)
    }
  }
}

// MARK: - Resolution

struct Match {
  let name: String
  let udid: String
  let os: String
  let runtimeIdentifier: String
  let destination: String
}

struct NearMiss {
  let kind: String  // "createDevice" | "versionMissing" | "unrecordable"
  let message: String
  let command: String?
}

struct Resolution {
  let platform: String
  let status: String  // "match" | "none" | "host" | "invalid"
  let matches: [Match]
  let nearMisses: [NearMiss]
  let warnings: [String]
}

func typeRenders(_ type: DeviceType, _ spec: PlatformSpec, warnings: inout Set<String>) -> Bool {
  guard let modelIdentifier = type.modelIdentifier, let scale = type.scale else { return false }
  guard let gamut = gamutByModelIdentifier[modelIdentifier] else {
    if modelIdentifier.hasPrefix("iPhone") || modelIdentifier.hasPrefix("iPad")
      || modelIdentifier.hasPrefix("iPod") || modelIdentifier.hasPrefix("AppleTV") {
      warnings.insert(
        "\(type.name) (\(modelIdentifier)) is not in the gamut table — update "
          + "Platform+Devices.swift and this script")
    }
    return false
  }
  return scale == spec.scale && gamut == spec.gamut
}

func resolve(_ platformString: String, runtimes: [Runtime], devicesByRuntime: [String: [Device]]) -> Resolution {
  guard let spec = parsePlatform(platformString) else {
    return Resolution(
      platform: platformString, status: "invalid", matches: [],
      nearMisses: [NearMiss(
        kind: "invalid",
        message: "not a valid platform string (expected e.g. \"iOS-18.5-p3@3x\")",
        command: nil)],
      warnings: [])
  }
  if spec.os != "iOS" && spec.os != "tvOS" {
    return Resolution(
      platform: platformString, status: "host", matches: [],
      nearMisses: [NearMiss(
        kind: "host",
        message: "\(spec.os) snapshots do not run on a simulator this script can resolve",
        command: nil)],
      warnings: [])
  }

  var warnings = Set<String>()
  var matches: [Match] = []
  var nearMisses: [NearMiss] = []

  let osRuntimes = runtimes.filter { $0.os == spec.os }
  let versionRuntimes = osRuntimes.filter { $0.version == spec.version }

  if versionRuntimes.isEmpty {
    let installed = osRuntimes.map { $0.version }.sorted()
    nearMisses.append(NearMiss(
      kind: "versionMissing",
      message: installed.isEmpty
        ? "no \(spec.os) simulator runtimes are installed"
        : "\(spec.os) \(spec.version) is not installed (installed: \(installed.joined(separator: ", "))); "
          + "re-recording on an installed version would change the snapshot filenames",
      command: nil))
  }

  for runtime in versionRuntimes {
    let typesByIdentifier = Dictionary(
      runtime.supportedDeviceTypes.map { ($0.identifier, $0) },
      uniquingKeysWith: { first, _ in first })
    let renderingTypes = runtime.supportedDeviceTypes.filter { typeRenders($0, spec, warnings: &warnings) }

    for device in devicesByRuntime[runtime.identifier] ?? [] {
      guard
        let type = typesByIdentifier[device.deviceTypeIdentifier],
        typeRenders(type, spec, warnings: &warnings)
        else { continue }
      matches.append(Match(
        name: device.name,
        udid: device.udid,
        os: runtime.name,
        runtimeIdentifier: runtime.identifier,
        destination: "platform=\(spec.os) Simulator,id=\(device.udid)"))
    }

    if matches.isEmpty {
      if let creatable = renderingTypes.first {
        nearMisses.append(NearMiss(
          kind: "createDevice",
          message: "\(runtime.name) is installed and \(creatable.name) would render "
            + "\(spec.gamut)@\(spec.scale)x, but no such device exists yet",
          command: "xcrun simctl create '\(creatable.name)' '\(creatable.identifier)' '\(runtime.identifier)'"))
      } else {
        nearMisses.append(NearMiss(
          kind: "unrecordable",
          message: "\(runtime.name) is installed, but none of its device types renders "
            + "\(spec.gamut)@\(spec.scale)x — this snapshot cannot be verified or recorded on this machine",
          command: nil))
      }
    }
  }

  matches.sort { ($0.name, $0.udid) < ($1.name, $1.udid) }
  return Resolution(
    platform: platformString,
    status: matches.isEmpty ? "none" : "match",
    matches: matches,
    nearMisses: matches.isEmpty ? nearMisses : [],
    warnings: warnings.sorted())
}

// MARK: - CLI

func usage() -> Never {
  FileHandle.standardError.write("""
    usage: snapshot-simulators.swift [--json] <platform-string> ...
           snapshot-simulators.swift [--json] --snapshots <directory> ...

    Platform strings look like "iOS-18.5-p3@3x", exactly as they appear in snapshot
    filenames and in SnapshotTesting failure messages. --snapshots scans directories
    for platform-suffixed snapshot files instead.\n
    """.data(using: .utf8)!)
  exit(64)
}

var arguments = Array(CommandLine.arguments.dropFirst())
let json = arguments.contains("--json")
arguments.removeAll { $0 == "--json" }
let scanSnapshots = arguments.first == "--snapshots"
if scanSnapshots { arguments.removeFirst() }
if arguments.isEmpty { usage() }

var platformStrings: [String] = []
if scanSnapshots {
  var found = Set<String>()
  for directory in arguments {
    guard let enumerator = FileManager.default.enumerator(atPath: directory) else {
      FileHandle.standardError.write("error: cannot read directory \(directory)\n".data(using: .utf8)!)
      exit(64)
    }
    for case let path as String in enumerator {
      if let platform = platformString(ofSnapshotFileNamed: (path as NSString).lastPathComponent) {
        found.insert(platform)
      }
    }
  }
  platformStrings = found.sorted()
  if platformStrings.isEmpty {
    FileHandle.standardError.write("no platform-suffixed snapshots found\n".data(using: .utf8)!)
    exit(1)
  }
} else {
  platformStrings = arguments
}

let runtimes = loadRuntimes()
let devicesByRuntime = loadDevices()
let resolutions = platformStrings.map {
  resolve($0, runtimes: runtimes, devicesByRuntime: devicesByRuntime)
}

if json {
  let output: [[String: Any]] = resolutions.map { resolution in
    [
      "platform": resolution.platform,
      "status": resolution.status,
      "matches": resolution.matches.map {
        [
          "name": $0.name, "udid": $0.udid, "os": $0.os,
          "runtimeIdentifier": $0.runtimeIdentifier, "destination": $0.destination,
        ]
      },
      "nearMisses": resolution.nearMisses.map { miss -> [String: Any] in
        var dictionary: [String: Any] = ["kind": miss.kind, "message": miss.message]
        if let command = miss.command { dictionary["command"] = command }
        return dictionary
      },
      "warnings": resolution.warnings,
    ]
  }
  let data = try! JSONSerialization.data(
    withJSONObject: output, options: [.prettyPrinted, .sortedKeys])
  print(String(data: data, encoding: .utf8)!)
} else {
  for resolution in resolutions {
    print("\(resolution.platform):")
    for match in resolution.matches {
      print("  \(match.name) (\(match.os))  \(match.udid)")
      print("    -destination '\(match.destination)'")
    }
    for miss in resolution.nearMisses {
      print("  \(miss.message)")
      if let command = miss.command { print("    \(command)") }
    }
    for warning in resolution.warnings {
      print("  warning: \(warning)")
    }
    print("")
  }
}

let unresolved = resolutions.filter { $0.status == "none" || $0.status == "invalid" }
exit(unresolved.isEmpty ? 0 : 1)
