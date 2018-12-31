# Codable

**Platforms:** All

## `.json`

**Value:** `Encodable`
<br>
**Format:** `String` (.json)

A snapshot strategy for comparing encodable structures based on their JSON representation.

#### Parameters:

  - `encoder: JSONEncoder` (optional)

#### Example:

``` swift
struct User { let bio: String, id: Int, name: String }
let user = User(bio: "Blobbed around the world.", id: 1, name: "Blobby")

assertSnapshot(matching: user, as: .json)
```

Records:

``` json
{
  "bio" : "Blobbed around the world.",
  "id" : 1,
  "name" : "Blobby"
}
```

## `.plist`

**Value:** `Encodable`
<br>
**Format:** `String` (.plist)

A snapshot strategy for comparing encodable structures based on their property list representation.

#### Parameters:

  - `encoder: PropertyListEncoder` (optional)

#### Example:

``` swift
struct User { let bio: String, id: Int, name: String }
let user = User(bio: "Blobbed around the world.", id: 1, name: "Blobby")

assertSnapshot(matching: user, as: .plist)
```

Records:

``` xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>bio</key>
  <string>Blobbed around the world.</string>
  <key>id</key>
  <integer>1</integer>
  <key>name</key>
  <string>Blobby</string>
</dict>
</plist>
```
