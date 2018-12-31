# URLRequest

**Platforms:** All

## `.raw`

**Value:** `URLRequest`
<br>
**Format:** `String` (.txt)

A snapshot strategy for comparing requests based on raw equality.

#### Example:

``` swift
assertSnapshot(matching: request, as: .raw)
```

Records:

```
POST http://localhost:8080/account
Cookie: pf_session={"userId":"1"}

email=blob%40pointfree.co&name=Blob
```
