# NSImage

**Platforms:** macOS

## `.image`

**Value:** `NSImage`
**Format:** `NSImage` (.png)

A snapshot strategy for comparing images based on pixel equality.

#### Parameters:

  - `precision: Float = 1`

    The percentage of pixels that must match.

#### Example:

``` swift
// Match reference as-is.
assertSnapshot(matching: image, as: .image)

// Allow for a 1% pixel difference.
assertSnapshot(matching: image, as: .image(precision: 0.99)
```