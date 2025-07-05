# Defining custom snapshot strategies

While XCSnapshotTesting comes with a wide variety of snapshot strategies, it can also be extended with
custom, user-defined strategies using the ``XCSnapshotTesting/Snapshot`` and
``XCSnapshotTesting/DiffAttachmentGenerator`` types.

## Snapshotting

The ``XCSnapshotTesting/Snapshot`` type represents the ability to transform a snapshottable value
(like a view or data structure) into a diffable format (like an image or text).

### Transforming existing strategies

Existing strategies can be transformed to work with new types using the `pullback` method.

For example, given the following `image` strategy on `UIView`:

``` swift
Snapshot<UIView, ImageBytes>.image
```

We can define an `image` strategy on `UIViewController` using the `pullback` method:

``` swift
extension AsyncSnapshot where Input: UIViewController, Output == ImageBytes {
  public static let image = AsyncSnapshot<UIView, ImageBytes>
    .image
    .pullback { viewController in viewController.view }
}
```

Pullback takes a transform function from the new strategy's value to the existing strategy's value,
in this case `(UIViewController) -> UIView`.

### Creating brand new strategies

Most strategies can be built from existing ones, but if you've defined your own
``XCSnapshotTesting/DiffAttachmentGenerator`` strategy, you may need to create a base ``XCSnapshotTesting/Snapshot``
value alongside it.

### Asynchronous Strategies

Some types need to be snapshot in an asynchronous fashion. ``XCSnapshotTesting/Snapshot`` offers
two APIs for building asynchronous strategies by utilizing a built-in ``Async`` type.

#### Async pullbacks

Alongside ``Snapshotting/pullback(_:)`` there is ``Snapshotting/asyncPullback(_:)``, which takes a
transform function `(NewStrategyValue) -> Async<ExistingStrategyValue>`.

For example, WebKit's `WKWebView` offers a callback-based API for taking image snapshots, where the
image is passed asynchronously to the callback block. While `pullback` would require the `UIImage`
to be returned from the transform function, `pullback` and `Async` allow us to pass the `image`
a value that can pass its callback along to the scope in which the image has been created.

``` swift
extension AsyncSnapshot where Input: WKWebView, Output == ImageBytes {
  public static let image = AsyncSnapshot<UIImage, Output>
    .image
    .pullback { webView in
      Async { 
        let image = try await webView.takeSnapshot(with: nil)
        return ImageBytes(rawValue: image)
      }
  }
}
```

#### Async initialization

`Snapshot` defines an alternate initializer to describe snapshot values in an asynchronous
fashion.

For example, were we to define a strategy for `WKWebView` _without_
``Snapshotting/asyncPullback(_:)``:

``` swift
extension AsyncSnapshot where Input: WKWebView, Output == ImageBytes {
  public static let image = AsyncSnapshot(
    pathExtension: "png",
    attachmentGenerator: .image,
    executor: Async { webView in
        let image = try await webView.takeSnapshot(with: nil)
        return ImageBytes(rawValue: image)
    }
  )
}
```

## DiffAttachmentGenerator

The ``XCSnapshotTesting/DiffAttachmentGenerator`` type represents the ability to compare 
`Value`s and convert them to and from ``XCSnapshotTesting/DiffAttachment``.
