# CALayer

**Platforms:** iOS, macOS, tvOS

## `.image`

**Value:** `CALayer`
<br>
**Format:** `NSImage`, `UIImage`

A snapshot strategy for comparing layers based on pixel equality.

#### Parameters:

  - `precision: Float = 1`

    The percentage of pixels that must match.

#### Example:

``` swift
// Match reference perfectly.
assertSnapshot(matching: layer, as: .image)

// Allow for a 1% pixel difference.
assertSnapshot(matching: layer, as: .image(precision: 0.99)
```
