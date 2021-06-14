
An attachment type.
There are some predefined types on backend but any type can be introduced and sent to backend.

``` swift
public struct AttachmentType: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral 
```

## Inheritance

`Codable`, `ExpressibleByStringLiteral`, `Hashable`, `RawRepresentable`

## Initializers

### `init(rawValue:)`

``` swift
public init(rawValue: String) 
```

### `init(stringLiteral:)`

``` swift
public init(stringLiteral value: String) 
```

## Properties

### `rawValue`

``` swift
public let rawValue: String
```

### `image`

Backend specified types.

``` swift
static let image 
```

### `file`

``` swift
static let file 
```

### `giphy`

``` swift
static let giphy 
```

### `video`

``` swift
static let video 
```

### `audio`

``` swift
static let audio 
```

### `linkPreview`

Application custom types.

``` swift
static let linkPreview 
```

### `unknown`

Is used when attachment with missing `type` comes.

``` swift
static let unknown 
```
