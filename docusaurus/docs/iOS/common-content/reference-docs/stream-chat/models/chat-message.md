---
title: ChatMessage
---

A type representing a chat message. `_ChatMessage` is an immutable snapshot of a chat message entity at the given time.

``` swift
@dynamicMemberLookup
public struct _ChatMessage<ExtraData: ExtraDataTypes> 
```

> 

Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).

## Inheritance

`Hashable`

## Properties

### `quotedMessageId`

Quoted message id.

``` swift
@available(*, deprecated, message: "Use quotedMessage?.id instead")
    var quotedMessageId: MessageId? 
```

If message is inline reply this property will contain id of the message quoted by this reply.

### `id`

A unique identifier of the message.

``` swift
public let id: MessageId
```

### `cid`

The ChannelId this message belongs to. This value can be temporarily `nil` for messages that are being removed from
the local cache, or when the local cache is in the process of invalidating.

``` swift
public let cid: ChannelId?
```

### `text`

The text of the message.

``` swift
public let text: String
```

### `type`

A type of the message.

``` swift
public let type: MessageType
```

### `command`

If the message was created by a specific `/` command, the command is saved in this variable.

``` swift
public let command: String?
```

### `createdAt`

Date when the message was created on the server. This date can differ from `locallyCreatedAt`.

``` swift
public let createdAt: Date
```

### `locallyCreatedAt`

Date when the message was created locally and scheduled to be send. Applies only for the messages of the current user.

``` swift
public let locallyCreatedAt: Date?
```

### `updatedAt`

A date when the message was updated last time.

``` swift
public let updatedAt: Date
```

### `deletedAt`

If the message was deleted, this variable contains a timestamp of that event, otherwise `nil`.

``` swift
public let deletedAt: Date?
```

### `arguments`

If the message was created by a specific `/` command, the arguments of the command are stored in this variable.

``` swift
public let arguments: String?
```

### `parentMessageId`

The ID of the parent message, if the message is a reply, otherwise `nil`.

``` swift
public let parentMessageId: MessageId?
```

### `showReplyInChannel`

If the message is a reply and this flag is `true`, the message should be also shown in the channel, not only in the
reply thread.

``` swift
public let showReplyInChannel: Bool
```

### `replyCount`

Contains the number of replies for this message.

``` swift
public let replyCount: Int
```

### `extraData`

Additional data associated with the message.

``` swift
public let extraData: ExtraData.Message
```

Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).

### `quotedMessage`

Quoted message.

``` swift
public var quotedMessage: _ChatMessage<ExtraData>? 
```

If message is inline reply this property will contain the message quoted by this reply.

### `isSilent`

A flag indicating whether the message is a silent message.

``` swift
public let isSilent: Bool
```

Silent messages are special messages that don't increase the unread messages count nor mark a channel as unread.

### `reactionScores`

The reactions to the message created by any user.

``` swift
public let reactionScores: [MessageReactionType: Int]
```

### `author`

The user which is the author of the message.

``` swift
public var author: _ChatUser<ExtraData.User> 
```

> 

### `mentionedUsers`

A list of users that are mentioned in this message.

``` swift
public var mentionedUsers: Set<_ChatUser<ExtraData.User>> 
```

> 

### `threadParticipants`

A list of users that participated in this message thread

``` swift
public var threadParticipants: Set<_ChatUser<ExtraData.User>> 
```

### `attachmentCounts`

The overall attachment count by attachment type.

``` swift
public var attachmentCounts: [AttachmentType: Int] 
```

### `latestReplies`

A list of latest 25 replies to this message.

``` swift
public var latestReplies: [_ChatMessage<ExtraData>] 
```

> 

### `localState`

A possible additional local state of the message. Applies only for the messages of the current user.

``` swift
public let localState: LocalMessageState?
```

Most of the time this value is `nil`. This value is always `nil` for messages not from the current user. A typical
use of this value is to check if a message is pending send/delete, and update the UI accordingly.

### `isFlaggedByCurrentUser`

An indicator whether the message is flagged by the current user.

``` swift
public let isFlaggedByCurrentUser: Bool
```

> 

### `latestReactions`

The latest reactions to the message created by any user.

``` swift
public var latestReactions: Set<_ChatMessageReaction<ExtraData>> 
```

> 

> 

### `currentUserReactions`

The entire list of reactions to the message left by the current user.

``` swift
public var currentUserReactions: Set<_ChatMessageReaction<ExtraData>> 
```

> 

### `isSentByCurrentUser`

`true` if the author of the message is the currently logged-in user.

``` swift
public let isSentByCurrentUser: Bool
```

### `pinDetails`

The message pinning information. Is `nil` if the message is not pinned.

``` swift
public let pinDetails: _MessagePinDetails<ExtraData>?
```

### `isPinned`

Indicates whether the message is pinned or not.

``` swift
public var isPinned: Bool 
```

### `imageAttachments`

Returns the attachments of `.image` type.

``` swift
var imageAttachments: [ChatMessageImageAttachment] 
```

> 

### `fileAttachments`

Returns the attachments of `.file` type.

``` swift
var fileAttachments: [ChatMessageFileAttachment] 
```

> 

### `videoAttachments`

Returns the attachments of `.video` type.

``` swift
var videoAttachments: [ChatMessageVideoAttachment] 
```

> 

### `giphyAttachments`

Returns the attachments of `.giphy` type.

``` swift
var giphyAttachments: [ChatMessageGiphyAttachment] 
```

> 

### `linkAttachments`

Returns the attachments of `.linkPreview` type.

``` swift
var linkAttachments: [ChatMessageLinkAttachment] 
```

> 

## Methods

### `attachments(payloadType:)`

Returns all the attachments with the payload of the provided type.

``` swift
func attachments<Payload: AttachmentPayload>(
        payloadType: Payload.Type
    ) -> [_ChatMessageAttachment<Payload>] 
```

> 

### `attachment(with:)`

Returns attachment for the given identifier.

``` swift
func attachment(with id: AttachmentId) -> AnyChatMessageAttachment? 
```

#### Parameters

  - id: Attachment identifier.

#### Returns

A type-erased attachment.

### `hash(into:)`

``` swift
public func hash(into hasher: inout Hasher) 
```

## Operators

### `==`

``` swift
public static func == (lhs: Self, rhs: Self) -> Bool 
```
