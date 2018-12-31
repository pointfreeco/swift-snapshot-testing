# String

**Platforms:** All

### `.lines`

**Value:** `String`
<br>
**Format:** `String` (.txt)

A snapshot strategy for comparing strings based on equality.

#### Example:

``` swift
assertSnapshot(matching: htmlString, as: .lines)
```
