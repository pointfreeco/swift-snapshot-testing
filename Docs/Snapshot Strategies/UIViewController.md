# UIViewController

**Platforms:** iOS, tvOS

## `.hierarchy`

**Value:** `UIViewController`
<br>
**Format:** `String` (.txt)

A snapshot strategy for comparing view controllers based on their embedded controller hierarchy.

#### Example

``` swift
assertSnapshot(matching: vc, as: .hierarchy)
```

Records:

```
<UITabBarController>, state: appeared, view: <UILayoutContainerView>
   | <UINavigationController>, state: appeared, view: <UILayoutContainerView>
   |    | <UIPageViewController>, state: appeared, view: <_UIPageViewControllerContentView>
   |    |    | <UIViewController>, state: appeared, view: <UIView>
   | <UINavigationController>, state: disappeared, view: <UILayoutContainerView> not in the window
   |    | <UIViewController>, state: disappeared, view: (view not loaded)
   | <UINavigationController>, state: disappeared, view: <UILayoutContainerView> not in the window
   |    | <UIViewController>, state: disappeared, view: (view not loaded)
   | <UINavigationController>, state: disappeared, view: <UILayoutContainerView> not in the window
   |    | <UIViewController>, state: disappeared, view: (view not loaded)
   | <UINavigationController>, state: disappeared, view: <UILayoutContainerView> not in the window
   |    | <UIViewController>, state: disappeared, view: (view not loaded)
```

## `.image`

**Value:** `UIViewController`
<br>
**Format:** `UIImage` (.png)

A snapshot strategy for comparing layers based on pixel equality.

#### Parameters:

  - `drawHierarchyInKeyWindow: Bool = false`

    Utilize the simulator's key window in order to render `UIAppearance` and `UIVisualEffect`s. This option requires a host application for your tests and will _not_ work for framework test targets.
    
    _Incompatible with the `on` parameter._
    
  - `on: ViewImageConfig`

    A set of device configuration settings.
    
    _Incompatible with the `drawHierarchyInKeyWindow` parameter._

  - `precision: Float = 1`

    The percentage of pixels that must match.

  - `size: CGSize = nil`

    A view size override.
    
  - `traits: UITraitCollection = .init()`

    A trait collection override.

#### Example:

``` swift
// Match reference as-is.
assertSnapshot(matching: vc, as: .image)

// Allow for a 1% pixel difference.
assertSnapshot(matching: vc, as: .image(precision: 0.99)

// Render as if on a certain device.
assertSnapshot(matching: vc, on: .iPhoneX(.portrait))

// Render at a certain size.
assertSnapshot(
  matching: vc,
  as: .image(size: .init(width: 375, height: 667)
)

// Render with a horizontally-compact size class.
assertSnapshot(
  matching: vc,
  as: .image(traits: .init(horizontalSizeClass: .regular))
)

// Match reference as-is.
assertSnapshot(matching: vc, as: .image)
```

**See also**: [`UIView`](#uiview).

## `.recursiveDescription`

**Value:** `UIViewController`
<br>
**Format:** `String` (.txt)

A snapshot strategy for comparing view controller views based on a recursive description of their properties and hierarchies.

#### Parameters:
    
  - `on: ViewImageConfig`

    A set of device configuration settings.

  - `size: CGSize = nil`

    A view size override.
    
  - `traits: UITraitCollection = .init()`

    A trait collection override.

#### Example

``` swift
// Layout on the current device.
assertSnapshot(matching: vc, as: .recursiveDescription)

// Layout as if on a certain device.
assertSnapshot(matching: vc, as: .recursiveDescription(on: .iPhoneSe(.portrait))
```

Records:

```
<UIView; frame = (0 0; 375 667); opaque = NO; layer = <CALayer>>
   | <UIImageView; frame = (0 0; 375 667); clipsToBounds = YES; opaque = NO; userInteractionEnabled = NO; layer = <CALayer>>
```
