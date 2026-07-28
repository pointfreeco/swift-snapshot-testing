# Choosing an image pixel format

Trade comparison speed, reference size and color accuracy for image snapshots.

## Overview

Image snapshots render the same way whatever ``SnapshotTestingConfiguration/ImagePixelFormat-swift.struct``
you choose. The format decides how each snapshot is stored as a reference and what it is compared in.

| Format | References | Compared in | Colors outside sRGB | `perceptualPrecision` measures |
| --- | --- | --- | --- | --- |
| ``SnapshotTestingConfiguration/ImagePixelFormat-swift.struct/automatic`` | The platform's PNG encoding of the render: 16-bit Display P3 for wide-gamut renders on iOS 26 and later | 8-bit sRGB | Clipped | Historical values |
| ``SnapshotTestingConfiguration/ImagePixelFormat-swift.struct/sRGB`` | 8-bit sRGB | 8-bit sRGB | Clipped | Historical values |
| `sRGB(bitDepth: .sixteen)` | 16-bit sRGB | 16-bit sRGB | Clipped | Historical values |
| ``SnapshotTestingConfiguration/ImagePixelFormat-swift.struct/displayP3`` | 8-bit Display P3 | 8-bit Display P3 | Compared | Actual color difference |
| `displayP3(bitDepth: .sixteen)` | 16-bit Display P3 | 16-bit Display P3 | Compared | Actual color difference |

The format applies on iOS, tvOS and macOS, including on Mac Catalyst. watchOS and visionOS have no
image strategies. This article describes iOS and tvOS; see <doc:ChoosingAnImagePixelFormat#On-macOS>
for how macOS differs. No format keeps HDR content brighter than SDR white.

### Performance

With `automatic` on iOS and tvOS, references are stored in whatever format UIKit encodes the render
as, while comparisons happen in 8-bit sRGB, so every comparison converts both the reference and the
snapshot. The other formats store references in the format they compare in: decoding a reference
into the comparison context is a copy, and a matching comparison converts only the snapshot, once.
They also store fully opaque snapshots without an alpha channel, which makes those references
smaller without changing how they compare.

As a rough guide, on an iPhone 18 Pro simulator running iOS 27.2, a matching assertion of a 390 × 844
point screen at 3× took:

| Format | Per assertion | Reference |
| --- | --- | --- |
| `automatic` | 200–300 ms | 390 KB |
| `sRGB` | about 55 ms | 201 KB |
| `sRGB(bitDepth: .sixteen)` | about 90 ms | 299 KB |
| `displayP3` | about 50 ms | 204 KB |
| `displayP3(bitDepth: .sixteen)` | about 100 ms | 318 KB |

Results vary with content, device and machine, so measure your own suite.

### Perceptual comparisons

When a snapshot doesn't match its reference exactly and `perceptualPrecision` is below 1, each
pixel's color difference (ΔE) is measured on the pixels that were compared, drawn at 16 bits so
rounding doesn't add differences of its own. `automatic` and `sRGB` keep the historical measure,
which reads encoded values as if they were linear: it overstates differences near black, where one
8-bit step measures about 3.5 ΔE, and understates them in mid-tones. The Display P3 formats measure
the actual color difference.

Snapshots taken with `drawHierarchyInKeyWindow: true` come from the render server, so they can
differ slightly between machines with different GPUs. A `perceptualPrecision` a little below 1
absorbs those differences; no format removes them.

### On macOS

`automatic` compares in the reference's own colorspace and bit depth instead of 8-bit sRGB, so it
keeps the wide-gamut colors of a Display P3 reference, and the same colors match across colorspaces
and bit depths. Its perceptual comparisons measure the images as recorded with the historical
measure when they share a colorspace, and color match them at the reference's bit depth when they
don't.

The other formats work as they do on iOS, which makes two differences from `automatic` worth
weighing. `sRGB` clips the wide-gamut colors `automatic` compares. And AppKit renders view
snapshots in 8-bit Generic RGB, which clips some saturated sRGB colors, so `sRGB` doesn't store
colors defined in 8-bit sRGB exactly: saturated reds and blues can be dozens of steps off. The
rendering is the same every run, so comparisons stay stable.

### Choosing a format

- Keep `automatic` to keep your existing references. Exact comparisons are unchanged on iOS and
  tvOS, perceptual ones measure as described above, and comparisons are slower than with the other
  formats.
- Choose `sRGB` for faster comparisons and smaller references. On iOS and tvOS it handles color and
  measures `perceptualPrecision` like `automatic`, and stores colors defined in 8-bit sRGB exactly.
  Without the platform's PNG encoding in the way, results close to a threshold can differ slightly
  from `automatic`.
- Choose `sRGB(bitDepth: .sixteen)` for `sRGB`'s color handling with differences smaller than one
  8-bit step kept, such as small changes to blending, gradients or anti-aliasing. It exists so sRGB
  offers the same bit depths as Display P3; those differences are rarely visible, and
  `displayP3(bitDepth: .sixteen)` keeps them too while also comparing colors outside sRGB.
- Choose `displayP3` when your app shows colors outside sRGB, such as Display P3 asset catalog
  colors or wide-gamut images. Two trade-offs come with it: about three quarters of the 8-bit sRGB
  colors share an 8-bit Display P3 code with a neighbor (mostly under 1 ΔE76 apart, at most about
  2), so some sRGB changes go undetected; and `perceptualPrecision` measures the actual color
  difference, so thresholds tuned for `automatic` can pass or fail differently.
- Choose `displayP3(bitDepth: .sixteen)` when color differences smaller than an 8-bit Display P3
  step must be caught. It keeps every Display P3 color, and every 8-bit sRGB color of a wide-gamut
  render, distinct; converting an 8-bit sRGB image still merges about 2% of its colors, neighbors
  one step apart in a component near zero, at most about 1.2 ΔE76 apart. References are about the
  size of `automatic`'s 16-bit ones, or around a fifth smaller for fully opaque snapshots, and
  comparisons cost about twice as much as 8-bit ones.

### Adopting a format

Set the format for a suite and re-record its references once:

```swift
@Suite(.snapshots(record: .all, imagePixelFormat: .sRGB))
struct FeatureSnapshotTests {
  // ...
}
```

With XCTest, wrap `invokeTest`:

```swift
override func invokeTest() {
  withSnapshotTesting(record: .all, imagePixelFormat: .sRGB) {
    super.invokeTest()
  }
}
```

Then remove `record: .all`. References recorded in one format still compare in another, but they
lose that format's benefits, and exact comparisons can fail on rounding differences.
