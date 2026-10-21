# Migrating to 1.20

Add `try` where code calls a ``Diffing``'s `toData` or `fromData` directly.

## Overview

``Diffing/toData`` and ``Diffing/fromData`` now throw, so a strategy can report a value it can't
encode or data it can't decode as a test failure instead of crashing. This is a source-breaking
change for code that calls them directly. Closures passed to
``Diffing/diff(toData:fromData:diffV2:)`` don't need to change: non-throwing closures still work.

## Calling another strategy's conversions

Code that calls `toData` or `fromData` directly, such as a strategy built on another one, needs
`try`:

@Row {
  @Column {
    ```swift
    // Before

    extension Diffing where Value == Screen {
      static let screen = Diffing.diff(
        toData: { Diffing<UIImage>.image.toData($0.image) },
        fromData: { Screen(image: Diffing<UIImage>.image.fromData($0)) }
      ) { old, new in
        Diffing<UIImage>.image.diffV2(old.image, new.image)
      }
    }
    ```
  }
  @Column {
    ```swift
    // After

    extension Diffing where Value == Screen {
      static let screen = Diffing.diff(
        toData: { try Diffing<UIImage>.image.toData($0.image) },
        fromData: { Screen(image: try Diffing<UIImage>.image.fromData($0)) }
      ) { old, new in
        Diffing<UIImage>.image.diffV2(old.image, new.image)
      }
    }
    ```
  }
}

Stored conversions need a throwing function type, for example
`let encode: (UIImage) throws -> Data = Diffing<UIImage>.image.toData`.

A call where errors can't be thrown, such as in a `diffV2` closure, needs `try?` instead, or the
enclosing function must throw:

```swift
{ old, new in
  guard let (message, _) = Diffing<UIImage>.image.diffV2(old.image, new.image) else { return nil }
  let attachments = (try? Diffing<UIImage>.image.toData(new.image))
    .map { [DiffAttachment.data($0, name: "new.png")] } ?? []
  return (message, attachments)
}
```

## Reporting errors from custom strategies

Instead of force unwrapping, throw an error that conforms to `LocalizedError`: its description
becomes the failure message.

## Image references

The image strategies now report unreadable references, such as empty files, Git LFS pointers and
truncated or corrupt PNGs, and snapshots that can't be encoded, as test failures instead of
crashing. With `record: .failed`, an unreadable reference is replaced by a new recording, unless
it's a Git LFS pointer, which is kept so `git lfs pull` can still download it. Otherwise the new
snapshot is attached and saved with the failure.
