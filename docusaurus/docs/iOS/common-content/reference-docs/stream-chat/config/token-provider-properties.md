
### `anonymous`

The provider that can be used when user is unknown.

``` swift
static var anonymous: Self 
```

## Methods

### `development(userId:)`

The provider that can be used during the development. It's handy since doesn't require a token.

``` swift
static func development(userId: UserId) -> Self 
```

#### Parameters

  - userId: The user identifier.

#### Returns

The new `TokenProvider` instance.

### `` `static`(_:) ``

The provider which can be used to provide a static token known on the client-side which doesn't expire.

``` swift
static func `static`(_ token: Token) -> Self 
```

#### Parameters

  - token: The token to be returned by the token provider.

#### Returns

The new `TokenProvider` instance.

### `guest(userId:name:imageURL:extraData:)`

The provider which designed to be used for guest users.

``` swift
static func guest(
        userId: UserId,
        name: String? = nil,
        imageURL: URL? = nil,
        extraData: ExtraData.User = .defaultValue
    ) -> Self 
```

#### Parameters

  - userId: The identifier a guest user will be created OR updated with if it exists.
  - name: The name a guest user will be created OR updated with if it exists.
  - imageURL: The avatar URL a guest user will be created OR updated with if it exists.
  - extraData: The extra data a guest user will be created OR updated with if it exists.

#### Returns

The new `TokenProvider` instance.

### `closure(_:)`

The token provider designed to be used when a token is dynamic (e.g. can change OR expire).

``` swift
static func closure(
        _ handler: @escaping (_ client: _ChatClient<ExtraData>, _ completion: @escaping (Result<Token, Error>) -> Void) -> Void
    ) -> Self 
```

#### Parameters

  - handler: The closure which should get the token and pass it to the `completion`.

#### Returns

