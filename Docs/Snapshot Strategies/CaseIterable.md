# CaseIterable

**Platforms:** All

## `.func(into:)`

**Value:** `CaseIterable`
<br>
**Format:** `String` (.csv)

A snapshot strategy for functions on `CaseIterable` types. It feeds every possible input into the function and puts the inputs and outputs into a CSV table.

#### Parameters:

  - `strategy: Snapshotting<A, Format>`

    A snapshot strategy on the output of the function you want to snapshot test.

#### Example:

```swift
enum Direction: String, CaseIterable {
  case up, down, left, right
  var rotatedLeft: Direction {
    switch self {
    case .up:    return .left
    case .down:  return .right
    case .left:  return .down
    case .right: return .up
    }
  }
}

assertSnapshot(
  matching: { $0.rotatedLeft },
  as: Snapshotting<Direction, String>.func(into: .description)
)
```

Records:

```csv
"up","left"
"down","right"
"left","down"
"right","up" 
```
