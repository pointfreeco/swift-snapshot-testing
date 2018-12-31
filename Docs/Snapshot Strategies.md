This library comes with a number of snapshot strategies that you can immediately start using. They are all values of the `Snapshotting<Value, Format>` type, where `Value` is the type you are snapshotting, and `Format` is the format you snapshotting _into_. The values are stored as static properties on `Snapshotting` so that you can leverage type inference with the `assertSnapshot` test function. For example, instead of specify the full path to a strategy like this:

```swift
assertSnapshot(matching: user, as: Snapshotting<String, String>.dump)
```

you can simply do:

```swift
assertSnapshot(matching: user, as: .dump)
```
