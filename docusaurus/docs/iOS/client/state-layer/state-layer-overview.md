---
title: State Layer
---

:::note
Available from `StreamChat` version 4.56.0.
:::

The `StreamChat` framework represents the Stream API with [controllers](../controllers/controllers-overview.md) which use completion handlers and delegates for communicating about state changes. In addition to controllers, we provide a new and modern way of interacting with the Stream API. It follows an architecture where we have objects interacting with the Stream API through async functions. These objects are accompanied with state objects that hold the current state. This architecture follows similar patterns as our [Video SDK for iOS](https://getstream.io/video/sdk/ios/).

While controllers use delegates, the state layer provides a way of observing data changes through `@Published` properties. Observable properties are part of state objects which conform to the `ObservableObject` protocol.

One of the important improvements of the new state layer is predictability of the current data state. While methods in controllers have completion handlers, these do not ensure that the data is up to date when the completion handler is called. The new state layer, on the other hand, is designed in way that if an async method call returns, the required API request has finished, and the state object holding the current state has been updated to include the change.

Every async method is safe to be called from any thread. Observable state objects are isolated to the main actor. This gives a guarantee that observable state changes and reads happen on the main actor. While state objects are isolated to the main actor, we can still access the state from non-main actor contexts which just requires to use the `await` keyword.

Let's consider an example below where we ask to load messages. When the `loadMessages(with:)` returns, we are guaranteed that the observable state object has all the loaded messages available.

```swift
try await chat.loadMessages(with: MessagesPagination(pageSize: pageSize))
let allMessages = chat.state.messages
```

## Types Representing the State

The state layer has objects representing different use-cases which enables accessing and manipulating data the Stream API provides. These types follow an architecture where high level types have methods for interacting with the Stream API and the state counterpart keeps the currently loaded data. The state object is observable and is backed by the local persistent store.

* ChannelList
  * ChannelListState
* Chat
  * ChatState
  * MessageState
* ConnectedUser
  * ConnectedUserState
* MemberList
  * MemberListState
* MessageSearch
  * MessageSearchState
* ReactionList
  * ReactionListState
* UserList
  * UserListState
* UserSearch
  * UserSearchState

These objects are created through factory methods in `ChatClient`. Factory methods create instances of `ChannelList`, `Chat`, `ConnectedUser`, `MemberList`, `MessageSearch`, `ReactionList`, `UserList`,  and `UserSearch`. The observable state is accessed through `state` properties what return the respective state object. `ChannelList`, `Chat`, `MemberList`, `ReactionList`, and `UserList` have a `get()` method for loading the default set of data from the Stream API.

### ConnectedUser

`ConnectedUser` and its `ConnectedUserState` represent the currently logged in user. We log in by calling `connectUser` method on the `ChatClient` instance. Please refer to our [tokens and authentication](https://getstream.io/chat/docs/ios-swift/tokens_and_authentication/?language=swift) documentation for more information on expiring and non-expiring tokens. `ConnectedUser` type enables setting up push notifications and set states, like muting a user in every channel or even blocking an user. Another common use-case is marking all the channels as read.

```swift
var connectedUser = try await chatClient.connectUser(
    userInfo: UserInfo(id: "<# Your User ID Here #>"),
    token: "<# Your User Token Here#>"
)
// Or while being logged in
connectedUser = try chatClient.makeConnectedUser()
// Register for push notifications
try await connectedUser.addDevice(
    .apn(
        token: apnTokenData, 
        providerName: "<# Your Stream's Push Configuration Name>"
    )
)
// Mute a user
try await connectedUser.muteUser("user-id")
// Block a user
try await connectedUser.blockUser("another-user-id")
// Mark all the channels as read
try await connectedUser.markAllChannelsRead()
// Read user data
let unreadCounts = connectedUser.state.user.unreadCount
let numberOfUnreadChannels = unreadCounts.channels
let numberOfUnreadMessages = unreadCounts.messages
// React to user data changes
connectedUser.state.$user
  .sink { changedUser in
      let changedUnreadCount = changedUser.unreadCount
  }
  .store(in: &cancellables)
```

### ChannelList

`ChannelList` and its `ChannelListState` enable querying a list of channels from the Stream API and provide an interface for loading channels in a paginated manner.

```swift
let query = ChannelListQuery(
    filter: .and([
        .equal(.type, to: .messaging), 
        .containMembers(userIds: ["thierry"])
    ]),
    sort: [Sorting(key: .lastMessageAt, isAscending: false)],
    pageSize: 10
)
let channelList = chatClient.makeChannelList(with: query)
// Local state of the channel list (state from previous sessions)
var channels = channelList.state.channels
// Load the first page of channels from the Stream API
try await channelList.get()
// Load more channels
try await channelList.loadMoreChannels()
// Access all the loaded channels
channels = channelList.state.channels
```

Since `ChannelListState` is observable, we can observe and react to channel list changes.

```swift
let cancellable = channelList.state
    .$channels
    .sink { channels in
        // Do something with channels
    }
```

### Chat

`Chat` and its `ChatState` represent the state of a channel. In addition, `Chat` has a method for retrieving an observable `MessageState` type which represents a single message and its observable state like reactions and replies.

Here is an example of creating an instance of `Chat`, using the offline state, refreshing it with server state and then paginating available messages.

```swift
let channelId = ChannelId(type: .messaging, id: "general")
let chat = chatClient.makeChat(for: channelId)
// Local state of the channel (state from previous sessions)
var messages = chat.state.messages
var members = chat.state.members
// Load the latest state from the Stream API and subscribe to data changes
try await chat.get(watch: true)
// Access all the loaded messages and members
messages = chat.state.messages
members = chat.state.members
// Load more messages
try await chat.loadOlderMessages()
// Access all the loaded messages
messages = chat.state.messages
```

:::tip Call `get(watch: true)` once per app lifetime
The get method loads the latest state from the Stream API and if we set watch to true, server-side events will keep your local state up to state.
:::

`Chat` has a `sendMessage` method for sending messages. Sending a message could be as simple as just sending a text or more complex like including attachments, quoting another message, marking it as pinned and including extra data.

```swift
let fileURL = URL(filePath: "<file url>")
let attachment = try AnyAttachmentPayload(
    localFileURL: fileURL,
    attachmentType: .file
)
try await chat.sendMessage(
    with: "Hello",
    attachments: [attachment],
    quote: "other-message-id",
    pinning: .noExpiration,
    extraData: [
      "my-custom-key": .string("and string value")
    ]
)
```

If we would like to create a message thread within a channel, the `Chat` type provides a `reply` method with all the before-mentioned arguments.

```swift
try await chat.reply(
    to: "parent-message-id",
    text: "Hi!",
    showReplyInChannel: true
)
```

Adding and deleting reactions is also done through `Chat`. 

```swift
try await chat.sendReaction(
    to: "message-id",
    with: "like",
    score: 1,
    enforceUnique: true,
    extraData: [
        "has-xyz-enabled": .bool(true)
    ]
)
try await chat.deleteReaction(
    from: "message-id",
    with: "like"
)
```

If we would like to observe or read a single message's state, then we can use the `MessageState` observable object. This type also gives access to all the loaded replies and reactions for the given message.

```swift
let messageState = try await chat.messageState(for: "message-id")
try await chat.loadMoreReplies(for: messageId)
// Access all the loaded replies
let replies = messageState.replies
// Load reactions
let reactionsBatch25 = try await chat.loadReactions(
    for: "message-id",
    pagination: Pagination(pageSize: 25)
)
// Paginate reactions by loading 10 more
let reactionsBatch10 = try await chat.loadMoreReactions(
    for: "message-id",
    limit: 10
)
// Access all the currently loaded reactions
let allLoadedReactions35 = messageState.reactions
```

:::note
Use `Chat` for loading all the reactions per message and `ReactionList` if you need to load reactions using a filter.
:::

### MemberList

`MemberList` and `MemberListState` represent channel members for the specified query. The query supports a wide variety of filters and sorting options. While `MemberList` provides advanced querying capabilities, it is not required if we would like to load all the channel members. For that purpose, `Chat` has built-in paginated loading methods for all the channel members.

```swift
let query = ChannelMemberListQuery(
        cid: ChannelId(type: .messaging, id: "general"),
        sort: [Sorting(key: .createdAt, isAscending: true)]
    )
let memberList = chatClient.makeMemberList(with: query)
// Local state of the member list (state from previous sessions)
var members = memberList.state.members
// Load the first page of members from the Stream API
try await memberList.get()
// Load more members
try await memberList.loadMoreMembers()
// Access all the loaded members
members = memberList.state.members
```

### MessageSearch

`MessageSearch` and `MessageSearchState` represent search results for messages. Messages can be searched using a combination of filters or just by a simple search term.

```swift
let messageSearch = chatClient.makeMessageSearch()
// Searching for messages containing "Stream"
try await messageSearch.search(text: "Stream")
// Or searching for messages in the specified channel containing "Stream"
try await messageSearch.search(query:
    MessageSearchQuery(
        channelFilter: .containMembers(userIds: ["john"]),
        messageFilter: .autocomplete(.text, text: "Stream")
    )
)
// Load more results
try await messageSearch.loadMoreMessages()
// All the loaded results
let matches = messageSearch.state.messages
```

### ReactionList

`ReactionList` and `ReactionListState` represent a list of messages reactions matching to a query. `ReactionList` is useful for cases where we want to query a list of message reactions using a filter.

```swift
let query = ReactionListQuery(
    messageId: messageId,
    filter: .equal(.reactionType, to: "like")
)
let reactionList = chatClient.makeReactionList(with: query)
// Load reactions for the query
try await reactionList.get()
// Load more reactions
try await reactionList.loadMoreReactions()
// All the loaded reactions
let users = reactionList.state.reactions
```

### UserList

`UserList` and `UserListState` represent a list of users matching to a query. `UserList` is useful for cases where we want to query a list of users filtered and sorted in a specific way.

```swift
let query = UserListQuery(
    filter: .in(.id, values: ["john", "jack", "jessie"]),
    sort: [Sorting(key: .lastActivityAt, isAscending: false)]
)
let userList = chatClient.makeUserList(with: query)
// Load users for the query
try await userList.get()
// Load more users
try await userList.loadMoreUsers()
// All the loaded users
let users = userList.state.users
```

### UserSearch

`UserSearch` and `UserSearchState` represent user search results. Although `UserList` and `UserSearch` are similar and use the same `UserListQuery`, the main difference is that `UserSearch` is optimized for interactive searching where the query changes often.

```swift
let userSearch = chatClient.makeUserSearch()
try await userSearch.search(term: "thi")
// Load more results
try await userSearch.loadMoreUsers()
// All the loaded results for "thi"
var users = userSearch.state.users
// Change the search term
try await userSearch.search(term: "thie")
// All the loaded results for "thie"
users = userSearch.state.users
```

## Listening to Web-Socket Events

Web-socket events are delivered whenever server side state changes. Stream chat's low-level client listens to these events and updates the local state accordingly. If there is a need, we can subscribe to these events using `ChatClient` for any events including channel events, and `Chat` for channel specific events. The latter offers convenience over the former.
```swift
// Every single event
chatClient.subscribe { event in
    // …
}
.store(in: &cancellables)

// A specific event
chatClient.subscribe(toEvent: ConnectionStatusUpdated.self) { event in
    // …
}
.store(in: &cancellables)

// Channel specific event
let channelId = ChannelId(type: .messaging, id: "general")
let chat = chatClient.makeChat(for: channelId)
chat.subscribe { event in
    // All the events only for this particular channel id
}
.store(in: &cancellables)

// Channel specific events filtered down to a single type
chat.subscribe(toEvent: ChannelHiddenEvent.self) { event in
    // …
}
.store(in: &cancellables)
```
