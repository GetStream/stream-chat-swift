---
title: ChatMessageController
---

`ChatMessageController` is a controller class which allows observing and mutating a chat message entity.

``` swift
public class _ChatMessageController<ExtraData: ExtraDataTypes>: DataController, DelegateCallable, DataStoreProvider 
```

Learn more about `ChatMessageController` and its usage in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#messages).

> 

Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).

## Inheritance

[`DataController`](../data-controller.md), [`DelegateCallable`](../delegate-callable.md), [`DataStoreProvider`](../../database/data-store-provider.md)

## Properties

### `statePublisher`

A publisher emitting a new value every time the state of the controller changes.

``` swift
public var statePublisher: AnyPublisher<DataController.State, Never> 
```

### `messageChangePublisher`

A publisher emitting a new value every time the message changes.

``` swift
public var messageChangePublisher: AnyPublisher<EntityChange<_ChatMessage<ExtraData>>, Never> 
```

### `repliesChangesPublisher`

A publisher emitting a new value every time the list of the replies of the message has changes.

``` swift
public var repliesChangesPublisher: AnyPublisher<[ListChange<_ChatMessage<ExtraData>>], Never> 
```

### `observableObject`

A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.

``` swift
public var observableObject: ObservableObject 
```

### `client`

The `ChatClient` instance this controller belongs to.

``` swift
public let client: _ChatClient<ExtraData>
```

### `cid`

The identified of the channel the message belongs to.

``` swift
public let cid: ChannelId
```

### `messageId`

The identified of the message this controllers represents.

``` swift
public let messageId: MessageId
```

### `message`

The message object this controller represents.

``` swift
public var message: _ChatMessage<ExtraData>? 
```

To observe changes of the message, set your class as a delegate of this controller or use the provided
`Combine` publishers.

### `replies`

The replies to the message the controller represents.

``` swift
public var replies: LazyCachedMapCollection<_ChatMessage<ExtraData>> 
```

To observe changes of the replies, set your class as a delegate of this controller or use the provided
`Combine` publishers.

### `listOrdering`

Describes the ordering the replies are presented.

``` swift
public var listOrdering: ListOrdering = .topToBottom 
```

> 

## Methods

### `synchronize(_:)`

``` swift
override public func synchronize(_ completion: ((Error?) -> Void)? = nil) 
```

### `editMessage(text:completion:)`

Edits the message this controller manages with the provided values.

``` swift
func editMessage(text: String, completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - text: The updated message text.
  - completion: The completion. Will be called on a **callbackQueue** when the network request is finished. If request fails, the completion will be called with an error.

### `deleteMessage(completion:)`

Deletes the message this controller manages.

``` swift
func deleteMessage(completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - completion: The completion. Will be called on a **callbackQueue** when the network request is finished. If request fails, the completion will be called with an error.

### `createNewReply(text:pinning:attachments:mentionedUserIds:showReplyInChannel:isSilent:quotedMessageId:extraData:completion:)`

Creates a new reply message locally and schedules it for send.

``` swift
func createNewReply(
        text: String,
        pinning: MessagePinning? = nil,
//        command: String? = nil,
//        arguments: String? = nil,
        attachments: [AnyAttachmentPayload] = [],
        mentionedUserIds: [UserId] = [],
        showReplyInChannel: Bool = false,
        isSilent: Bool = false,
        quotedMessageId: MessageId? = nil,
        extraData: ExtraData.Message = .defaultValue,
        completion: ((Result<MessageId, Error>) -> Void)? = nil
    ) 
```

#### Parameters

  - text: Text of the message.
  - pinning: Pins the new message. `nil` if should not be pinned.
  - attachments: An array of the attachments for the message. `Note`: can be built-in types, custom attachment types conforming to `AttachmentEnvelope` protocol and `ChatMessageAttachmentSeed`s.
  - showReplyInChannel: Set this flag to `true` if you want the message to be also visible in the channel, not only in the response thread.
  - quotedMessageId: An id of the message new message quotes. (inline reply)
  - extraData: Additional extra data of the message object.
  - completion: Called when saving the message to the local DB finishes.

### `loadPreviousReplies(before:limit:completion:)`

Loads previous messages from backend.

``` swift
func loadPreviousReplies(
        before messageId: MessageId? = nil,
        limit: Int = 25,
        completion: ((Error?) -> Void)? = nil
    ) 
```

#### Parameters

  - messageId: ID of the last fetched message. You will get messages `older` than the provided ID. In case no replies are fetched you will get the first `limit` number of replies.
  - limit: Limit for page size.
  - completion: The completion. Will be called on a **callbackQueue** when the network request is finished. If request fails, the completion will be called with an error.

### `loadNextReplies(after:limit:completion:)`

Loads new messages from backend.

``` swift
func loadNextReplies(
        after messageId: MessageId? = nil,
        limit: Int = 25,
        completion: ((Error?) -> Void)? = nil
    ) 
```

#### Parameters

  - messageId: ID of the current first message. You will get messages `newer` then the provided ID.
  - limit: Limit for page size.
  - completion: The completion. Will be called on a **callbackQueue** when the network request is finished. If request fails, the completion will be called with an error.

### `flag(completion:)`

Flags the message this controller manages.

``` swift
func flag(completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.

### `unflag(completion:)`

Unflags the message this controller manages.

``` swift
func unflag(completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.

### `addReaction(_:score:enforceUnique:extraData:completion:)`

Adds new reaction to the message this controller manages.

``` swift
func addReaction(
        _ type: MessageReactionType,
        score: Int = 1,
        enforceUnique: Bool = false,
        extraData: ExtraData.MessageReaction = .defaultValue,
        completion: ((Error?) -> Void)? = nil
    ) 
```

#### Parameters

  - type: The reaction type.
  - score: The reaction score.
  - enforceUnique: If set to `true`, new reaction will replace all reactions the user has (if any) on this message.
  - extraData: The reaction extra data.
  - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.

### `deleteReaction(_:completion:)`

Deletes the reaction from the message this controller manages.

``` swift
func deleteReaction(
        _ type: MessageReactionType,
        completion: ((Error?) -> Void)? = nil
    ) 
```

#### Parameters

  - type: The reaction type.
  - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.

### `pin(_:completion:)`

Pin the message this controller manages.

``` swift
func pin(_ pinning: MessagePinning, completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - pinning: The pinning expiration information. It supports setting an infinite expiration, setting a date, or the amount of time a message is pinned.
  - completion: A completion block with an error if the request was failed.

### `unpin(completion:)`

Unpins the message this controller manages.

``` swift
func unpin(completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - completion: A completion block with an error if the request was failed.

### `restartFailedAttachmentUploading(with:completion:)`

Updates local state of attachment with provided `id` to be enqueued by attachment uploader.

``` swift
func restartFailedAttachmentUploading(
        with id: AttachmentId,
        completion: ((Error?) -> Void)? = nil
    ) 
```

#### Parameters

  - id: The attachment identifier.
  - completion: The completion. Will be called on a **callbackQueue** when the database operation is finished. If operation fails, the completion will be called with an error.

### `resendMessage(completion:)`

Changes local message from `.sendingFailed` to `.pendingSend` so it is enqueued by message sender worker.

``` swift
func resendMessage(completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - completion: The completion. Will be called on a **callbackQueue** when the database operation is finished. If operation fails, the completion will be called with an error.

### `dispatchEphemeralMessageAction(_:completion:)`

Executes the provided action on the message this controller manages.

``` swift
func dispatchEphemeralMessageAction(_ action: AttachmentAction, completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - action: The action to take.
  - completion: The completion. Will be called on a **callbackQueue** when the operation is finished. If operation fails, the completion is called with the error.

### `setDelegate(_:)`

Sets the provided object as a delegate of this controller.

``` swift
func setDelegate<Delegate: _ChatMessageControllerDelegate>(_ delegate: Delegate?) where Delegate.ExtraData == ExtraData 
```

> 

#### Parameters

  - delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object alive if you want keep receiving updates.
