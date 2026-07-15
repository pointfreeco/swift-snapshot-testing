# Migrating to 1.19

Update custom ``Diffing`` strategies to support Swift Testing attachments.

## Overview

Prior to 1.19, the ``Diffing`` type's `diff` closure returned `[XCTAttachment]` to describe
failure artifacts (such as reference images, failure images, and difference images). This meant that
when running tests in Swift Testing, these attachments could not be surfaced because `XCTAttachment`
is an XCTest-only type.

Version 1.19 introduces a new ``DiffAttachment`` enum and updated APIs so that failure artifacts are
automatically surfaced as Swift Testing
[attachments](https://developer.apple.com/documentation/testing/attachment) when tests are run in
a `@Test`.

## Updating custom `Diffing` strategies

If you have defined a custom ``Diffing`` strategy, you will need to update it to use the new
``Diffing/diff(toData:fromData:diffV2:)`` static method and return ``DiffAttachment`` values
instead of `XCTAttachment`s.

@Row {
  @Column {
    ```swift
    // Before

    extension Diffing where Value == MyImage {
      static let myImage = Diffing(
        toData: { $0.pngData()! },
        fromData: { MyImage(data: $0)! }
      ) { old, new in
        guard old != new else { return nil }
        let oldAttachment = XCTAttachment(image: old)
        oldAttachment.name = "reference"
        let newAttachment = XCTAttachment(image: new)
        newAttachment.name = "failure"
        return (
          "Images did not match",
          [oldAttachment, newAttachment]
        )
      }
    }
    ```
  }
  @Column {
    ```swift
    // After

    extension Diffing where Value == MyImage {
      static let myImage = Diffing.diff(
        toData: { $0.pngData()! },
        fromData: { MyImage(data: $0)! }
      ) { old, new in
        guard old != new else { return nil }
        return (
          "Images did not match",
          [
            .data(old.pngData()!, name: "reference.png"),
            .data(new.pngData()!, name: "failure.png"),
          ]
        )
      }
    }
    ```
  }
}

The changes are:

  * Use ``Diffing/diff(toData:fromData:diffV2:)`` instead of `Diffing.init(toData:fromData:diff:)`.
    The initializer is now deprecated.

  * Return ``DiffAttachment`` values instead of `XCTAttachment`. The ``DiffAttachment`` enum has
    two cases:

    * ``DiffAttachment/data(_:name:)``: Provides raw `Data` and a file name. This is the preferred
      case because it works in both XCTest and Swift Testing contexts. The library will
      automatically convert it to the appropriate attachment type for the active test runner.

    * ``DiffAttachment/xcTest(_:)``: Wraps an `XCTAttachment` directly. This case is provided for
      backwards compatibility, but attachments wrapped this way will **not** appear in Swift Testing
      results.

## Accessing `diffV2` directly

If you are accessing the `diff` property on an existing ``Diffing`` value, it has been deprecated
in favor of ``Diffing/diffV2``, which returns `[DiffAttachment]` instead of `[XCTAttachment]`:

@Row {
  @Column {
    ```swift
    // Before

    if let (message, attachments) =
      diffing.diff(expected, actual) {
      // attachments: [XCTAttachment]
    }
    ```
  }
  @Column {
    ```swift
    // After

    if let (message, attachments) =
      diffing.diffV2(expected, actual) {
      // attachments: [DiffAttachment]
    }
    ```
  }
}

## Backwards compatibility

The deprecated `diff` property and initializer continue to work. If you are not yet ready to
migrate, your existing custom diffing strategies will compile with a deprecation warning. However,
attachments created through the deprecated path will only appear in XCTest results, not in Swift
Testing.
