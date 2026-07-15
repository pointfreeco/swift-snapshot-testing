# Multi-Simulator Snapshots

Image snapshots are only reproducible on a simulator that renders identically to the one
that recorded them. Three traits (besides the operating system itself) genuinely affect
rendering: the **OS version**, the display **gamut** (sRGB vs. Display P3), and the display
**scale** (@1x/@2x/@3x). Two simulators that agree on all of these — say, an iPhone 16 and
an iPhone 16 Pro on iOS 18.5 — produce pixel-identical snapshots and can share reference
files; two that differ cannot.

Setting `SnapshotTesting.supportedPlatforms` makes this explicit. Snapshot filenames then
embed the platform that recorded them, each platform keeps its own reference files, and an
unlisted simulator is prevented from silently recording references nobody maintains.

```swift
// e.g. in your test case's setUp, or once per test target
SnapshotTesting.supportedPlatforms = [
  Platform.iOSSimulator(named: "iPhone 16e", version: "18.5")!,
  Platform(rawValue: "iOS-26.0-p3@3x")!,
]
```

## Filename format

```
<testName>-<identifier>-<os>-<version>-<gamut>@<scale>x.<ext>
e.g.  testMyView-1-iOS-18.5-p3@3x.png
```

The platform suffix matches the anchored pattern

```
(iOS|macOS|tvOS|linux)-[0-9]+(\.[0-9]+){0,2}-(unspecified|srgb|p3)@[0-9]+x
```

`testName` and `identifier` are sanitized but may themselves contain `-`, so always parse
the platform from the **end** of the basename, never by splitting on `-` from the left.
Version strings are normalized: at least `major.minor`, with trailing zero components
beyond that dropped (`18.5.0` is written `18.5`; `26.3.1` stays `26.3.1`).

## `supportedPlatforms` semantics

| Value | Filenames | Behavior |
|---|---|---|
| `nil` (default) | `testName.identifier.ext` | Legacy: no platform tracking; snapshots recorded on one simulator spuriously fail on any other. |
| `[]` | platform-suffixed | The first snapshot of a test can always be recorded (bootstrapping). Once any reference exists, only listed platforms may record new ones. |
| non-empty | platform-suffixed | As above; listed platforms may also record even when other platforms' references exist. |

When a test runs on a platform that has no reference file while an incompatible platform's
reference exists, the failure message names the current platform string and the exact
`supportedPlatforms` line to add — recording never happens implicitly on an unlisted
simulator, even with `record = true`.

## Finding a simulator for a platform (humans and agents)

A platform string is a complete requirement specification. To resolve one against the
simulators installed *right now*:

```sh
scripts/snapshot-simulators.swift iOS-18.5-p3@3x         # one or more platform strings
scripts/snapshot-simulators.swift --snapshots Tests/     # or scan for snapshot files
scripts/snapshot-simulators.swift --json iOS-18.5-p3@3x  # machine-readable
```

For each platform the script prints matching simulators with a paste-ready
`-destination` argument, or the nearest miss:

- the runtime is installed and a suitable device type exists but no device is created
  (it prints the `xcrun simctl create` command);
- the OS version is not installed (it lists the versions that are — re-recording on one
  of those is a deliberate choice: it changes the snapshot filenames);
- no installed device type renders that gamut/scale — the snapshot **cannot** be verified
  or recorded on this machine.

The exit status is 0 only when every requested platform resolved. The `--json` schema is
an array of:

```json
{
  "platform": "iOS-18.5-p3@3x",
  "status": "match | none | host | invalid",
  "matches": [
    {"name": "…", "udid": "…", "os": "iOS 18.5", "runtimeIdentifier": "…", "destination": "platform=iOS Simulator,id=…"}
  ],
  "nearMisses": [{"kind": "createDevice | versionMissing | unrecordable", "message": "…", "command": "…?"}],
  "warnings": ["…"]
}
```

**Recipe for agents** maintaining snapshots in a project that uses this library:

1. Run the test suite. A failure mentioning an "incompatible simulator" (or a missing
   reference) states the current platform string; existing snapshot filenames state the
   platforms references were recorded on.
2. Run `scripts/snapshot-simulators.swift --json <platform-string> …` for the platforms
   you need to verify or record.
3. For each `"status": "match"`, run the tests with the printed `destination` via
   `xcodebuild … -destination '<destination>'`, once per required platform.
4. If a `nearMiss` has a `command`, run it and retry. If the status is `"none"` with kind
   `versionMissing` or `unrecordable`, report that the snapshot cannot be
   verified/recorded on this machine — choosing to re-record on a different platform is a
   decision for a human (it rewrites reference files).

## How resolution works (and the gamut table)

OS versions come from `xcrun simctl list runtimes`, and each device type's scale and model
identifier come from its CoreSimulator `profile.plist` — both read live, so answers
reflect the current machine. Display gamut appears in no CoreSimulator metadata, so the
library maintains it per device model in `Platform.knownSimulatedDevices`
([Platform+Devices.swift](../Sources/SnapshotTesting/Platform+Devices.swift)), which also
backs `Platform.iOSSimulator(named:version:)`. When a new Xcode ships new device types,
the resolver warns about unknown models: add them to the table **and** to the mirrored
gamut map in [scripts/snapshot-simulators.swift](../scripts/snapshot-simulators.swift)
(sRGB vs. P3 is in Apple's published display specs). Apple TV gamut entries are currently
unverified.

Note the difference between this and `.image(on: .iPhoneSe)`: a `ViewImageConfig` simulates
a *device layout* (size, safe areas, traits) from any host simulator; `Platform` identifies
the *host simulator itself*, which determines how those layouts rasterize.

## Upgrading

There is no migration from legacy filenames. To adopt `supportedPlatforms` in an existing
suite: set it, delete the contents of your `__Snapshots__` directories, and re-record on
each supported platform.
