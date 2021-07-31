---
title: ChatMessageLayoutOptionsResolver
---

Resolves layout options for the message at given `indexPath`.

``` swift
open class _ChatMessageLayoutOptionsResolver<ExtraData: ExtraDataTypes> 
```

## Initializers

### `init(minTimeIntervalBetweenMessagesInGroup:)`

Creates the `_ChatMessageLayoutOptionsResolver` with the given `minTimeIntervalBetweenMessagesInGroup` value

``` swift
public init(minTimeIntervalBetweenMessagesInGroup: TimeInterval = 30) 
```

## Properties

### `minTimeIntervalBetweenMessagesInGroup`

The minimum time interval between messages to treat them as a single message group.

``` swift
public let minTimeIntervalBetweenMessagesInGroup: TimeInterval
```

## Methods

### `optionsForMessage(at:in:with:)`

``` swift
@available(*, deprecated, message: "Use the same method with the appearance parameter instead")
    open func optionsForMessage(
        at indexPath: IndexPath,
        in channel: _ChatChannel<ExtraData>,
        with messages: AnyRandomAccessCollection<_ChatMessage<ExtraData>>
    ) -> ChatMessageLayoutOptions 
```

### `optionsForMessage(at:in:with:appearance:)`

Calculates layout options for the message.

``` swift
open func optionsForMessage(
        at indexPath: IndexPath,
        in channel: _ChatChannel<ExtraData>,
        with messages: AnyRandomAccessCollection<_ChatMessage<ExtraData>>,
        appearance: Appearance
    ) -> ChatMessageLayoutOptions 
```

#### Parameters

  - indexPath: The index path of the cell displaying the message.
  - channel: The channel message is related to.
  - messages: The list of messages in the channel.
  - appearance: The appearance theme in use.

#### Returns

The layout options describing the components and layout of message content view.

### `isMessageLastInSequence(messageIndexPath:messages:)`

Says whether the message at given `indexPath` is the last one in a sequence of messages
sent by a single user where the time delta between near by messages
is `<= minTimeIntervalBetweenMessagesInGroup`.

``` swift
open func isMessageLastInSequence(
        messageIndexPath: IndexPath,
        messages: AnyRandomAccessCollection<_ChatMessage<ExtraData>>
    ) -> Bool 
```

Returns `true` if one of the following conditions is met:
1\. the message at `messageIndexPath` is the most recent one in the channel
2\. the message sent after the message at `messageIndexPath` has different author
3\. the message sent after the message at `messageIndexPath` has the same author but the
time delta between messages is bigger than `minTimeIntervalBetweenMessagesInGroup`

#### Parameters

  - messageIndexPath: The index path of the target message.
  - messages: The list of loaded channel messages.

#### Returns

Returns `true` if the message ends the sequence of messages from a single author.
