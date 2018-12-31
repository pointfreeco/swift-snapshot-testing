# SKScene

**Platforms:** iOS, macOS, tvOS

### `.image`

**Value:** `SKScene`
<br>
**Format:** `UIImage`, `NSImage` (.png)

A snapshot strategy for comparing SpriteKit scenes based on pixel equality.

#### Parameters:

  - `precision: Float = 1`

    The percentage of pixels that must match.

  - `size: CGSize`

    The size of the scene.

#### Example:

``` swift
assertSnapshot(
  matching: scene,
  as: .image(size: .init(width: 640, height: 480))
)
```

**See also**: [`NSView`](#nsview), [`UIView`](#uiview).
