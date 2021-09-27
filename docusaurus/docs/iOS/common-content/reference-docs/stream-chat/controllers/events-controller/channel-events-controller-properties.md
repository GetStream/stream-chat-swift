
### `cid`

``` swift
public var cid: ChannelId? 
```

## Methods

### `sendEvent(_:completion:)`

Sends a custom event to the channel with `cid`.

``` swift
public func sendEvent<T: CustomEventPayload>(_ payload: T, completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - payload: A custom event payload to be sent.
