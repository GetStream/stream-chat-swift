
### `description`

``` swift
public var description: String 
```

### `type`

The type of the channel the id belongs to.

``` swift
var type: ChannelType 
```

### `id`

The id of the channel without the encoded type information.

``` swift
var id: String 
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
