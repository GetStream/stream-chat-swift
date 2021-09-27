
### `rawValue`

``` swift
public let rawValue: String
```

### `userId`

``` swift
public let userId: UserId
```

### `expiration`

``` swift
public let expiration: Date?
```

### `isExpired`

``` swift
public var isExpired: Bool 
```

### `anonymous`

The token that can be used when user is unknown.

``` swift
static var anonymous: Self 
```

Is used by `anonymous` token provider.

## Methods

### `development(userId:)`

The token which can be used during the development.

``` swift
static func development(userId: UserId) -> Self 
```

