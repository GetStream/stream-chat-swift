
### `type`

An event type.

``` swift
public let type: EventType
```

### `cid`

A channel identifier the event is observed in.

``` swift
public let cid: ChannelId
```

### `userId`

A user identifier the event is sent by.

``` swift
public let userId: UserId
```

### `createdAt`

An event creation date.

``` swift
public let createdAt: Date
```

## Methods

### `payload(ofType:)`

Decodes a payload of the given type from the event.

``` swift
func payload<T: CustomEventPayload>(ofType: T.Type) -> T? 
```

#### Parameters

  - ofType: The type of payload the custom fields should be treated as.

#### Returns

