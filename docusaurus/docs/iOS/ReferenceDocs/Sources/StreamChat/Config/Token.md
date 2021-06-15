
The type is designed to store the JWT and the user it is related to.

``` swift
public struct Token: Decodable, Equatable, ExpressibleByStringLiteral 
```

## Inheritance

`Decodable`, `Equatable`, `ExpressibleByStringLiteral`

## Initializers

### `init(stringLiteral:)`

Created a new `Token` instance.

``` swift
public init(stringLiteral value: StringLiteralType) 
```

#### Parameters

  - value: The JWT string value. It must be in valid format and contain `user_id` in payload.

### `init(rawValue:)`

Creates a `Token` instance from the provided `rawValue` if it's valid.

``` swift
public init(rawValue: String) throws 
```

#### Parameters

  - rawValue: The token string in JWT format.

#### Throws

`ClientError.InvalidToken` will be thrown if token string is invalid.

### `init(from:)`

``` swift
public init(from decoder: Decoder) throws 
```

## Properties

### `rawValue`

``` swift
public let rawValue: String
```

### `userId`

``` swift
public let userId: UserId
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

Is used by `development(userId:)` token provider.
