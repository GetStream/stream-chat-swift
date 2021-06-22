---
id: chatclient 
title: ChatClient
slug: /ReferenceDocs/Sources/StreamChat/chatclient
---

The root object representing a Stream Chat.

``` swift
public class _ChatClient<ExtraData: ExtraDataTypes> 
```

Typically, an app contains just one instance of `ChatClient`. However, it's possible to have multiple instances if your use
case requires it (i.e. more than one window with different workspaces in a Slack-like app).

> 

## Inheritance

[`ConnectionDetailsProviderDelegate`](APIClient/ConnectionDetailsProviderDelegate), [`ConnectionStateDelegate`](WebSocketClient/ConnectionStateDelegate)

## Initializers

### `init(config:tokenProvider:completion:)`

Creates a new instance of `ChatClient`.

``` swift
public convenience init(
        config: ChatClientConfig,
        tokenProvider: _TokenProvider<ExtraData>,
        completion: ((Error?) -> Void)? = nil
    ) 
```

#### Parameters

  - config: The config object for the `Client`. See `ChatClientConfig` for all configuration options.
  - tokenProvider: The `_TokenProvider<ExtraData>` instance that incapsulates the logic of obtaining a JWT token used to communicate with REST-API.
  - completion: The completion that will be called once the **first** user session for the given token is setup.

## Properties

### `currentUserId`

The `UserId` of the currently logged in user.

``` swift
@Atomic public internal(set) var currentUserId: UserId?
```

### `connectionStatus`

The current connection status of the client.

``` swift
public internal(set) var connectionStatus: ConnectionStatus = .initialized
```

To observe changes in the connection status, create an instance of `CurrentChatUserController`, and use it to receive
callbacks when the connection status changes.

### `config`

The config object of the `ChatClient` instance.

``` swift
public let config: ChatClientConfig
```

This value can't be mutated and can only be set when initializing a new `ChatClient` instance.

### `tokenProvider`

``` swift
public var tokenProvider: _TokenProvider<ExtraData>
```

## Methods

### `channelController(for:)`

Creates a new `ChatChannelController` for the channel with the provided id.

``` swift
func channelController(for cid: ChannelId) -> _ChatChannelController<ExtraData> 
```

#### Parameters

  - cid: The id of the channel this controller represents.

#### Returns

A new instance of `ChatChannelController`.

### `channelController(for:)`

Creates a new `ChatChannelController` for the channel with the provided channel query.

``` swift
func channelController(for channelQuery: _ChannelQuery<ExtraData>) -> _ChatChannelController<ExtraData> 
```

#### Parameters

  - channelQuery: The ChannelQuery this controller represents

#### Returns

A new instance of `ChatChannelController`.

### `channelController(createChannelWithId:name:imageURL:team:members:isCurrentUserMember:invites:extraData:)`

Creates a `ChatChannelController` that will create a new channel, if the channel doesn't exist already.

``` swift
func channelController(
        createChannelWithId cid: ChannelId,
        name: String? = nil,
        imageURL: URL? = nil,
        team: String? = nil,
        members: Set<UserId> = [],
        isCurrentUserMember: Bool = true,
        invites: Set<UserId> = [],
        extraData: ExtraData.Channel = .defaultValue
    ) throws -> _ChatChannelController<ExtraData> 
```

It's safe to call this method for already existing channels. However, if you queried the channel before and you're sure it exists locally,
it can be faster and more convenient to use `channelController(for cid: ChannelId)` to create a controller for it.

#### Parameters

  - cid: The `ChannelId` for the new channel.
  - name: The new channel name.
  - imageURL: The new channel avatar URL.
  - team: Team for new channel.
  - members: Ds for the new channel members.
  - isCurrentUserMember: If set to `true` the current user will be included into the channel. Is `true` by default.
  - invites: IDs for the new channel invitees.
  - extraData: Extra data for the new channel.

#### Throws

`ClientError.CurrentUserDoesNotExist` if there is no currently logged-in user.

#### Returns

A new instance of `ChatChannelController`.

### `channelController(createDirectMessageChannelWith:type:isCurrentUserMember:name:imageURL:team:extraData:)`

Creates a `ChatChannelController` that will create a new channel with the provided members without having to specify
the channel id explicitly. This is great for direct message channels because the channel should be uniquely identified by
its members. If the channel for these members already exist, it will be reused.

``` swift
func channelController(
        createDirectMessageChannelWith members: Set<UserId>,
        type: ChannelType = .messaging,
        isCurrentUserMember: Bool = true,
        name: String? = nil,
        imageURL: URL? = nil,
        team: String? = nil,
        extraData: ExtraData.Channel = .defaultValue
    ) throws -> _ChatChannelController<ExtraData> 
```

It's safe to call this method for already existing channels. However, if you queried the channel before and you're sure it exists locally,
it can be faster and more convenient to use `channelController(for cid: ChannelId)` to create a controller for it.

#### Parameters

  - members: Members for the new channel. Must not be empty.
  - type: The type of the channel.
  - isCurrentUserMember: If set to `true` the current user will be included into the channel. Is `true` by default.
  - name: The new channel name.
  - imageURL: The new channel avatar URL.
  - team: Team for the new channel.
  - extraData: Extra data for the new channel.

#### Throws

  - `ClientError.ChannelEmptyMembers` if `members` is empty.
  - `ClientError.CurrentUserDoesNotExist` if there is no currently logged-in user.

#### Returns

A new instance of `ChatChannelController`.

### `channelListController(query:)`

Creates a new `ChannelListController` with the provided channel query.

``` swift
public func channelListController(query: _ChannelListQuery<ExtraData.Channel>) -> _ChatChannelListController<ExtraData> 
```

#### Parameters

  - query: The query specify the filter and sorting of the channels the controller should fetch.

#### Returns

A new instance of `ChannelController`.

### `watcherListController(query:)`

Creates a new `_ChatChannelWatcherListController` with the provided query.

``` swift
public func watcherListController(query: ChannelWatcherListQuery) -> _ChatChannelWatcherListController<ExtraData> 
```

#### Parameters

  - query: The query specifying the pagination options for watchers the controller should fetch.

#### Returns

A new instance of `_ChatChannelMemberListController`.

### `connectionController()`

Creates a new `ChatConnectionController` instance.

``` swift
func connectionController() -> _ChatConnectionController<ExtraData> 
```

#### Returns

A new instance of `ChatConnectionController`.

### `currentUserController()`

Creates a new `CurrentUserController` instance.

``` swift
func currentUserController() -> _CurrentChatUserController<ExtraData> 
```

#### Returns

A new instance of `CurrentChatUserController`.

### `memberController(userId:in:)`

Creates a new `_ChatChannelMemberController` for the user with the provided `userId` and `cid`.

``` swift
func memberController(userId: UserId, in cid: ChannelId) -> _ChatChannelMemberController<ExtraData> 
```

#### Parameters

  - userId: The user identifier.
  - cid: The channel identifier.

#### Returns

A new instance of `_ChatChannelMemberController`.

### `memberListController(query:)`

Creates a new `_ChatChannelMemberListController` with the provided query.

``` swift
public func memberListController(
        query: _ChannelMemberListQuery<ExtraData.User>
    ) -> _ChatChannelMemberListController<ExtraData> 
```

#### Parameters

  - query: The query specify the filter and sorting options for members the controller should fetch.

#### Returns

A new instance of `_ChatChannelMemberListController`.

### `messageController(cid:messageId:)`

Creates a new `MessageController` for the message with the provided id.

``` swift
func messageController(cid: ChannelId, messageId: MessageId) -> _ChatMessageController<ExtraData> 
```

#### Parameters

  - cid: The channel identifier the message relates to.
  - messageId: The message identifier.

#### Returns

A new instance of `MessageController`.

### `userSearchController()`

Creates a new `_ChatUserSearchController` with the provided user query.

``` swift
public func userSearchController() -> _ChatUserSearchController<ExtraData> 
```

#### Parameters

  - query: The query specify the filter and sorting of the users the controller should fetch.

#### Returns

A new instance of `_ChatUserSearchController`.

### `userController(userId:)`

Creates a new `_ChatUserController` for the user with the provided `userId`.

``` swift
func userController(userId: UserId) -> _ChatUserController<ExtraData> 
```

#### Parameters

  - userId: The user identifier.

#### Returns

A new instance of `_ChatUserController`.

### `userListController(query:)`

Creates a new `_ChatUserListController` with the provided user query.

``` swift
public func userListController(query: _UserListQuery<ExtraData.User> = .init()) -> _ChatUserListController<ExtraData> 
```

#### Parameters

  - query: The query specify the filter and sorting of the users the controller should fetch.

#### Returns

A new instance of `_ChatUserListController`.
