---
title: ChatClient
---

The root object representing a Stream Chat.

``` swift
public class ChatClient 
```

Typically, an app contains just one instance of `ChatClient`. However, it's possible to have multiple instances if your use
case requires it (i.e. more than one window with different workspaces in a Slack-like app).

## Inheritance

[`ConnectionDetailsProviderDelegate`](../api-client/connection-details-provider-delegate), [`ConnectionStateDelegate`](../web-socket-client/connection-state-delegate)

## Initializers

### `init(config:tokenProvider:)`

Creates a new instance of `ChatClient`.

``` swift
public convenience init(
        config: ChatClientConfig,
        tokenProvider: TokenProvider? = nil
    ) 
```

#### Parameters

  - config: The config object for the `Client`. See `ChatClientConfig` for all configuration options.
  - tokenProvider: In case of token expiration this closure is used to obtain a new token

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

In case of token expiration this property is used to obtain a new token

``` swift
public var tokenProvider: TokenProvider?
```

## Methods

### `setToken(token:)`

Sets the user token to the client, this method is only needed to perform API calls
without connecting as a user.
You should only use this in special cases like a notification service or other background process

``` swift
public func setToken(token: Token) 
```

### `connectUser(userInfo:token:completion:)`

Connects authorized user

``` swift
public func connectUser(
        userInfo: UserInfo,
        token: Token,
        completion: ((Error?) -> Void)? = nil
    ) 
```

#### Parameters

  - userInfo: User info that is passed to the `connect` endpoint for user creation
  - token: Authorization token for the user.
  - completion: The completion that will be called once the **first** user session for the given token is setup.

### `connectGuestUser(userInfo:completion:)`

Connects a guest user

``` swift
public func connectGuestUser(
        userInfo: UserInfo,
        completion: ((Error?) -> Void)? = nil
    ) 
```

#### Parameters

  - userInfo: User info that is passed to the `connect` endpoint for user creation
  - extraData: Extra data for user that is passed to the `connect` endpoint for user creation.
  - completion: The completion that will be called once the **first** user session for the given token is setup.

### `connectAnonymousUser(completion:)`

Connects anonymous user

``` swift
public func connectAnonymousUser(completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

  - completion: The completion that will be called once the **first** user session for the given token is setup.

### `disconnect()`

Disconnects the chat client from the chat servers. No further updates from the servers
are received.

``` swift
public func disconnect() 
```

### `channelController(for:messageOrdering:)`

Creates a new `ChatChannelController` for the channel with the provided id.

``` swift
func channelController(for cid: ChannelId, messageOrdering: MessageOrdering = .topToBottom) -> ChatChannelController 
```

#### Parameters

  - cid: The id of the channel this controller represents.
  - messageOrdering: Describes the ordering the messages are presented.

#### Returns

A new instance of `ChatChannelController`.

### `channelController(for:messageOrdering:)`

Creates a new `ChatChannelController` for the channel with the provided channel query.

``` swift
func channelController(
        for channelQuery: ChannelQuery,
        messageOrdering: MessageOrdering = .topToBottom
    ) -> ChatChannelController 
```

#### Parameters

  - channelQuery: The ChannelQuery this controller represents
  - messageOrdering: Describes the ordering the messages are presented.

#### Returns

A new instance of `ChatChannelController`.

### `channelController(createChannelWithId:name:imageURL:team:members:isCurrentUserMember:messageOrdering:invites:extraData:)`

Creates a `ChatChannelController` that will create a new channel, if the channel doesn't exist already.

``` swift
func channelController(
        createChannelWithId cid: ChannelId,
        name: String? = nil,
        imageURL: URL? = nil,
        team: String? = nil,
        members: Set<UserId> = [],
        isCurrentUserMember: Bool = true,
        messageOrdering: MessageOrdering = .topToBottom,
        invites: Set<UserId> = [],
        extraData: [String: RawJSON] = [:]
    ) throws -> ChatChannelController 
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
  - messageOrdering: Describes the ordering the messages are presented.
  - invites: IDs for the new channel invitees.
  - extraData: Extra data for the new channel.

#### Throws

`ClientError.CurrentUserDoesNotExist` if there is no currently logged-in user.

#### Returns

A new instance of `ChatChannelController`.

### `channelController(createDirectMessageChannelWith:type:isCurrentUserMember:messageOrdering:name:imageURL:team:extraData:)`

Creates a `ChatChannelController` that will create a new channel with the provided members without having to specify
the channel id explicitly. This is great for direct message channels because the channel should be uniquely identified by
its members. If the channel for these members already exist, it will be reused.

``` swift
func channelController(
        createDirectMessageChannelWith members: Set<UserId>,
        type: ChannelType = .messaging,
        isCurrentUserMember: Bool = true,
        messageOrdering: MessageOrdering = .topToBottom,
        name: String? = nil,
        imageURL: URL? = nil,
        team: String? = nil,
        extraData: [String: RawJSON]
    ) throws -> ChatChannelController 
```

It's safe to call this method for already existing channels. However, if you queried the channel before and you're sure it exists locally,
it can be faster and more convenient to use `channelController(for cid: ChannelId)` to create a controller for it.

#### Parameters

  - members: Members for the new channel. Must not be empty.
  - type: The type of the channel.
  - isCurrentUserMember: If set to `true` the current user will be included into the channel. Is `true` by default.
  - messageOrdering: Describes the ordering the messages are presented.
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
public func channelListController(query: ChannelListQuery) -> ChatChannelListController 
```

#### Parameters

  - query: The query specify the filter and sorting of the channels the controller should fetch.

#### Returns

A new instance of `ChannelController`.

### `watcherListController(query:)`

Creates a new `_ChatChannelWatcherListController` with the provided query.

``` swift
public func watcherListController(query: ChannelWatcherListQuery) -> ChatChannelWatcherListController 
```

#### Parameters

  - query: The query specifying the pagination options for watchers the controller should fetch.

#### Returns

A new instance of `ChatChannelMemberListController`.

### `connectionController()`

Creates a new `ChatConnectionController` instance.

``` swift
func connectionController() -> ChatConnectionController 
```

#### Returns

A new instance of `ChatConnectionController`.

### `currentUserController()`

Creates a new `CurrentUserController` instance.

``` swift
func currentUserController() -> CurrentChatUserController 
```

#### Returns

A new instance of `CurrentChatUserController`.

### `channelEventsController(for:)`

Creates a new `ChannelEventsController` that can be used to listen to system events
related to the channel with `cid` and to send custom events.

``` swift
func channelEventsController(for cid: ChannelId) -> ChannelEventsController 
```

#### Parameters

  - cid: A channel identifier.

#### Returns

A new instance of `ChannelEventsController`.

### `eventsController()`

Creates a new `EventsController` that can be used for event listening.

``` swift
func eventsController() -> EventsController 
```

#### Returns

A new instance of `EventsController`.

### `memberController(userId:in:)`

Creates a new `ChatChannelMemberController` for the user with the provided `userId` and `cid`.

``` swift
func memberController(userId: UserId, in cid: ChannelId) -> ChatChannelMemberController 
```

#### Parameters

  - userId: The user identifier.
  - cid: The channel identifier.

#### Returns

A new instance of `ChatChannelMemberController`.

### `memberListController(query:)`

Creates a new `ChatChannelMemberListController` with the provided query.

``` swift
public func memberListController(
        query: ChannelMemberListQuery
    ) -> ChatChannelMemberListController 
```

#### Parameters

  - query: The query specify the filter and sorting options for members the controller should fetch.

#### Returns

A new instance of `ChatChannelMemberListController`.

### `messageController(cid:messageId:)`

Creates a new `MessageController` for the message with the provided id.

``` swift
func messageController(cid: ChannelId, messageId: MessageId) -> ChatMessageController 
```

#### Parameters

  - cid: The channel identifier the message relates to.
  - messageId: The message identifier.

#### Returns

A new instance of `MessageController`.

### `messageSearchController()`

Creates a new `MessageSearchController` with the provided message query.

``` swift
func messageSearchController() -> ChatMessageSearchController 
```

#### Parameters

  - query: The query specify the filter of the messages the controller should fetch.

#### Returns

A new instance of `MessageSearchController`.

### `userSearchController()`

Creates a new `_ChatUserSearchController` with the provided user query.

``` swift
public func userSearchController() -> ChatUserSearchController 
```

#### Parameters

  - query: The query specify the filter and sorting of the users the controller should fetch.

#### Returns

A new instance of `_ChatUserSearchController`.

### `userController(userId:)`

Creates a new `_ChatUserController` for the user with the provided `userId`.

``` swift
func userController(userId: UserId) -> ChatUserController 
```

#### Parameters

  - userId: The user identifier.

#### Returns

A new instance of `_ChatUserController`.

### `userListController(query:)`

Creates a new `_ChatUserListController` with the provided user query.

``` swift
public func userListController(query: UserListQuery = .init()) -> ChatUserListController 
```

#### Parameters

  - query: The query specify the filter and sorting of the users the controller should fetch.

#### Returns

A new instance of `_ChatUserListController`.
