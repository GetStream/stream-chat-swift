
A type representing a message reaction. `_ChatMessageReaction` is an immutable snapshot
of a message reaction entity at the given time.

``` swift
@dynamicMemberLookup
public struct _ChatMessageReaction<ExtraData: ExtraDataTypes>: Hashable 
```

> 

Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).

## Inheritance

`Hashable`

## Properties

### `type`

The reaction type.

``` swift
public let type: MessageReactionType
```

### `score`

The reaction score.

``` swift
public let score: Int
```

### `createdAt`

The date the reaction was created.

``` swift
public let createdAt: Date
```

### `updatedAt`

The date the reaction was last updated.

``` swift
public let updatedAt: Date
```

### `extraData`

The reaction's extra data.

``` swift
public let extraData: ExtraData.MessageReaction
```

### `author`

The author.

``` swift
public let author: _ChatUser<ExtraData.User>
```
