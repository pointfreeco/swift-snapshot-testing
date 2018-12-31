# Any

**Platforms:** All

These snapshot strategies work for _any_ type, although the information they capture may vary greatly dependening on the type. These strategies offer a good starting off point to snapshot values, but many times you will want a more domain-specific snapshot strategy for your types.

## `.dump`

**Value:** `Any`
<br>
**Format:** `String`

A snapshot strategy that captures a textual representation of any value by dumping the contesnts of the value. Instead of the built-in Swift [`dump`](https://developer.apple.com/documentation/swift/1539127-dump) function we use a port of its functionality with a few key differences:

* It sorts data that is inherently unsorted, such as dictionaries and sets. This provides a deterministic snapshot.
* It strips pointer memory addresses.
* It provides a hook for supplying custom textual dumps of your own types by conforming to the `AnySnapshotStringConvertible` protocol.

#### Example:

``` swift
struct User { let bio: String, id: Int, name: String }
let user = User(bio: "Blobbed around the world.", id: 1, name: "Blobby")

assertSnapshot(matching: user, as: .dump)
```

Records:

```
▿ User
  - bio: "Blobbed around the world."
  - id: 1
  - name: "Blobby"
```

**See also**: [`.description`](#description).

## `.description`

**Value:** `Any`
<br>
**Format:** `String`

A snapshot strategy that captures a textual representation of any value by invoking the `String.init(describing:)` initializer.

#### Example:

``` swift
struct User { let bio: String, id: Int, name: String }
let user = User(bio: "Blobbed around the world.", id: 1, name: "Blobby")

assertSnapshot(matching: user, as: .description)
```

Records:

```
User(bio: "Blobbed around the world.", id: 1, name: "Blobby")
```

**See also**: [`.dump`](#dump).
