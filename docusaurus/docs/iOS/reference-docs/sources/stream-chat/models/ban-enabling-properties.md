
### `timeoutInMinutes`

The default timeout in minutes until the ban is automatically expired.

``` swift
public var timeoutInMinutes: Int? 
```

### `reason`

The default reason the ban was created.

``` swift
public var reason: String? 
```

## Methods

### `isEnabled(for:)`

Returns true is the ban is enabled for the channel.

``` swift
public func isEnabled(for channel: ChatChannel) -> Bool 
```

#### Parameters

