
A protocol defining extra data types used by `ChatClient`.

``` swift
public protocol ExtraDataTypes 
```

You can add additional (extra) data to entities in the chat system. For now, you can add extra data to `ChatUser`,
`ChatChannel`, and `ChatMessage`.

Example usage:

``` 
  enum CustomDataTypes: ExtraDataTypes {
    typealias Channel = MyCustomChannelExtraData
    typealias Message = MyCustomMessageExtraData
  }

  let client = Client<CustomDataTypes>(currentUser: user, config: config)
```

## Requirements

### User

An extra data type for `ChatUser`.

``` swift
associatedtype User: UserExtraData = NoExtraData
```

### Message

An extra data type for `ChatMessage`.

``` swift
associatedtype Message: MessageExtraData = NoExtraData
```

### Channel

An extra data type for `ChatChannel`.

``` swift
associatedtype Channel: ChannelExtraData = NoExtraData
```

### MessageReaction

An extra data type for `ChatMessageReaction`.

``` swift
associatedtype MessageReaction: MessageReactionExtraData = NoExtraData
```
