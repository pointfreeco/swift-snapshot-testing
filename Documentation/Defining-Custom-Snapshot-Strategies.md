# Defining Custom Snapshot Strategies

While SnapshotTesting comes with [a wide variety of snapshot strategies](Available-Snapshot-Strategies.md), it can also be extended with custom, user-defined strategies using the [`Snapshotting`](#snapshottingvalue-format) and [`Diffing`](#diffingvalue) types.

## `Snapshotting<Value, Format>`

The [`Snapshotting`](../Sources/SnapshotTesting/Snapshotting.swift) type represents the ability to transform a snapshottable value (like a view or data structure) into a diffable format (like an image or text).

### Transforming Existing Strategies

Existing strategies can be transformed to work with new types using the `pullback` method.

For example, given the following `image` strategy on `UIView`:

``` swift
Snapshotting<UIView, UIImage>.image
```

We can define an `image` strategy on `UIViewController` using the `pullback` method:

``` swift
extension Snapshotting where Value == UIViewController, Format == UIImage {
  public static let image: Snapshotting = 
    Snapshotting<UIView, UIImage>.image.pullback { vc in vc.view }
}
```

Pullback takes a transform function from the new strategy's value to the existing strategy's value, in this case `(UIViewController) -> UIView`.

### Creating Brand New Strategies

Most strategies can be built from existing ones, but if you've defined your own [`Diffing`](#diffingvalue) strategy, you may need to create a base `Snapshotting` value alongside it.

### Asynchronous Strategies

Some types need to be snapshot in an asynchronous fashion. `Snapshotting` offers two APIs for building asynchronous strategies by utilizing a built-in [`Async`](../Sources/SnapshotTesting/Async.swift) type.

#### `asyncPullback`

Alongside [`pullback`](#transforming-sxisting-strategies), `Snapshotting` defines `asyncPullback`, which takes a transform function `(NewStrategyValue) -> Async<ExistingStrategyValue>`.

For example, WebKit's `WKWebView` offers a callback-based API for taking image snapshots, where the image is passed asynchronously to the callback block. While `pullback` would require the `UIImage` to be returned from the transform function, `asyncPullback` and `Async` allow us to pass the `image`  a value that can pass its callback along to the scope in which the image has been created.

``` swift
extension Snapshotting where Value == WKWebView, Format == UIImage {
  public static let image: Snapshotting = Snapshotting<UIImage, UIImage>.image
    .asyncPullback { webView in
    
      Async { callback in
        webView.takeSnapshot(with: nil) { image, error in
          callback(image!)
        }
      }
  }
}
```

#### Async Initializer

`Snapshotting` defines an alternate initializer to describe snapshotting values in an asynchronous fashion.

For example, were we to define a strategy for `WKWebView` _without_ [`asyncPullback`](#asyncpullback):

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

## `Diffing<Value>`

The [`Diffing`](../Sources/SnapshotTesting/Diffing.swift) type represents the ability to compare `Value`s and convert them to and from `Data`.
