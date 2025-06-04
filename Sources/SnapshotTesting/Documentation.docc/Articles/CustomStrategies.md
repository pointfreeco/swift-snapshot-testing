# Defining custom snapshot strategies

While SnapshotTesting comes with a wide variety of snapshot strategies, it can also be extended with
custom, user-defined strategies using the ``SnapshotTesting/Snapshotting`` and
``SnapshotTesting/Diffing`` types.

## Snapshotting

The ``SnapshotTesting/Snapshotting`` type represents the ability to transform a snapshottable value
(like a view or data structure) into a diffable format (like an image or text).

### Transforming existing strategies

Existing strategies can be transformed to work with new types using the `pullback` method.

For example, given the following `image` strategy on `UIView`:

``` swift
Snapshotting<UIView, UIImage>.image
```

We can define an `image` strategy on `UIViewController` using the `pullback` method:

``` swift
extension Snapshotting where Value == UIViewController, Format == UIImage {
  public static let image: Snapshotting = Snapshotting<UIView, UIImage>
    .image
    .pullback { viewController in viewController.view }
}
```

Pullback takes a transform function from the new strategy's value to the existing strategy's value,
in this case `(UIViewController) -> UIView`.

### Creating brand new strategies

Most strategies can be built from existing ones, but if you've defined your own
``SnapshotTesting/Diffing`` strategy, you may need to create a base ``SnapshotTesting/Snapshotting``
value alongside it.

### Asynchronous Strategies

Some types need to be snapshot in an asynchronous fashion. ``SnapshotTesting/Snapshotting`` offers
two APIs for building asynchronous strategies by utilizing a built-in ``Async`` type.

#### Async pullbacks

Alongside ``Snapshotting/pullback(_:)`` there is ``Snapshotting/asyncPullback(_:)``, which takes a
transform function `(NewStrategyValue) -> Async<ExistingStrategyValue>`.

For example, WebKit's `WKWebView` offers a callback-based API for taking image snapshots, where the
image is passed asynchronously to the callback block. While `pullback` would require the `UIImage`
to be returned from the transform function, `asyncPullback` and `Async` allow us to pass the `image`
a value that can pass its callback along to the scope in which the image has been created.

``` swift
extension Snapshotting where Value == WKWebView, Format == UIImage {
  public static let image: Snapshotting = Snapshotting<UIImage, UIImage>
    .image
    .asyncPullback { webView in
      Async { callback in
        webView.takeSnapshot(with: nil) { image, error in
          callback(image!)
        }
      }
  }
}
```

#### Async initialization

`Snapshotting` defines an alternate initializer to describe snapshotting values in an asynchronous
fashion.

For example, were we to define a strategy for `WKWebView` _without_
``Snapshotting/asyncPullback(_:)``:

``` swift
extension Snapshotting where Value == WKWebView, Format == UIImage {
  public static let image = Snapshotting(
    pathExtension: "png",
    diffing: .image,
    asyncSnapshot: { webView in
      Async { callback in
        webView.takeSnapshot(with: nil) { image, error in
          callback(image!)
        }
      }
    }
  )
}
```

## SwiftUI Considerations

When working with SwiftUI views, you can control the rendering method using the `renderingMode` 
parameter to ensure proper snapshot consistency across different iOS versions and complex shapes.

### Rendering Modes

SwiftUI views with complex shapes (such as `RoundedRectangle` with `.continuous` style) may render 
differently when using Core Graphics layer rendering versus the system's native drawing hierarchy. 
The `renderingMode` parameter gives you explicit control over this behavior:

``` swift
// Default: Automatic detection (recommended)
assertSnapshot(of: mySwiftUIView, as: .image)
assertSnapshot(of: mySwiftUIView, as: .image(renderingMode: .auto))

// Always use high-accuracy rendering (requires host application)
assertSnapshot(of: mySwiftUIView, as: .image(renderingMode: .enabled))

// Always use layer rendering (works in framework tests)
assertSnapshot(of: mySwiftUIView, as: .image(renderingMode: .disabled))
```

### Automatic Mode (`.auto`)

The default `.auto` mode intelligently detects SwiftUI content and uses `drawHierarchy` rendering 
for better accuracy when a key window is available, gracefully falling back to layer rendering 
in framework test environments.

### Framework Test Compatibility

When using `.auto` mode, the library automatically adapts to framework test environments where 
no key window is available. For complex SwiftUI views that may have minor rendering differences 
in framework tests, consider using perceptual precision:

``` swift
assertSnapshot(of: myView, as: .image(
  renderingMode: .auto,
  perceptualPrecision: 0.98  // Allow minor rendering differences
))
```

## Diffing

The ``SnapshotTesting/Diffing`` type represents the ability to compare `Value`s and convert them to
and from `Data`.
