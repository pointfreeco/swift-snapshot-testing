# UIView

**Platforms:** iOS, tvOS

## `.image`

**Value:** `UIView`
<br>
**Format:** `UIImage` (.png)

A snapshot strategy for comparing layers based on pixel equality.

**Note:** Includes `SCNView`, `SKView`, `WKWebView`.

#### Parameters:

  - `drawHierarchyInKeyWindow: Bool = false`

    Utilize the simulator's key window in order to render `UIAppearance` and `UIVisualEffect`s. This option requires a host application for your tests and will _not_ work for framework test targets.

  - `precision: Float = 1`

    The percentage of pixels that must match.

  - `size: CGSize = nil`

    A view size override.
    
  - `traits: UITraitCollection = .init()`

    A trait collection override.

#### Example:

``` swift
// Match reference as-is.
assertSnapshot(matching: view, as: .image)

// Allow for a 1% pixel difference.
assertSnapshot(matching: view, as: .image(precision: 0.99)

// Render at a certain size.
assertSnapshot(
  matching: view,
  as: .image(size: .init(width: 44, height: 44)
)

// Render with a horizontally-compact size class.
assertSnapshot(
  matching: view,
  as: .image(traits: .init(horizontalSizeClass: .regular))
)
```

## `.recursiveDescription`

**Value:** `UIView`
<br>
**Format:** `String` (.txt)

A snapshot strategy for comparing views based on a recursive description of their properties and hierarchies.

#### Parameters:

  - `size: CGSize = nil`

    A view size override.

  - `traits: UITraitCollection = .init()`

    A trait collection override.

#### Example

``` swift
// Layout on the current device.
assertSnapshot(matching: view, as: .recursiveDescription)

// Layout with a certain size.
assertSnapshot(matching: view, as: .recursiveDescription(size: .init(width: 22, height: 22))

// Layout with a certain trait collection.
assertSnapshot(matching: view, as: .recursiveDescription(traits: .init(horizontalSizeClass: .regular))
```

Records:

```
<UIButton; frame = (0 0; 22 22); opaque = NO; layer = <CALayer>>
   | <UIImageView; frame = (0 0; 22 22); clipsToBounds = YES; opaque = NO; userInteractionEnabled = NO; layer = <CALayer>>
```
