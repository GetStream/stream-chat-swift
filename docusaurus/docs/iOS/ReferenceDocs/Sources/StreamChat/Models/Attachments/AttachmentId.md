
An object that uniquely identifies a message attachment.

``` swift
public struct AttachmentId: Hashable 
```

## Inheritance

`Hashable`, `RawRepresentable`

## Initializers

### `init(cid:messageId:index:)`

``` swift
public init(
        cid: ChannelId,
        messageId: MessageId,
        index: Int
    ) 
```

### `init?(rawValue:)`

``` swift
public init?(rawValue: String) 
```

## Properties

### `cid`

The cid of the channel the attachment belongs to.

``` swift
public let cid: ChannelId
```

### `messageId`

The id of the message the attachments belongs to.

``` swift
public let messageId: MessageId
```

### `index`

The position of the attachment within the message. The first attachment index is 0, then 1, etc.

``` swift
public let index: Int
```

### `rawValue`

``` swift
public var rawValue: String 
```
