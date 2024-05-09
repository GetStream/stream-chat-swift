---
title: State Layer
---

:::note
Available from `StreamChat` version 4.55.0.
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

These objects are created through factory methods in `ChatClient`. Factory methods create instances of `ChannelList`, `Chat`, `ConnectedUser`, `MemberList`, `MessageSearch`, `ReactionList`, `UserList`,  and `UserSearch`. The observable state is accessed through `state` properties what return the respective state object. `ChannelList`, `Chat`, `MemberList`, `ReactionList`, and `UserList` have a `get()` method for fetching the default set of data from the Stream API.

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
// local state of the channel list (state from previous sessions)
var channels = channelList.state.channels
// fetch the first page of channels from the Stream API
try await channelList.get()
// fetch more channels
try await channelList.loadMoreChannels()
// access all the fetched channels
channels = channelList.state.channels
```

Since `ChannelListState` is observable, we can observe and react to channel list changes.

```swift
let cancellable = channelList.state
    .$channels
    .sink { channels in
        // do something with channels
    }
```

### Chat

`Chat` and its `ChatState` represent the state of a channel. In addition, `Chat` has a method for retrieving an observable `MessageState` type which represents a single message and its observable state like reactions and replies.

:::note
Use `Chat` for loading all the reactions per message and `ReactionList` if you need to load reactions using a filter.
:::

```swift
let channelId = ChannelId(type: .messaging, id: "general")
let chat = chatClient.makeChat(for: channelId)
// local state of the channel (state from previous sessions)
var messages = chat.state.messages
var members = chat.state.members
// fetch the latest state from the Stream API and subscribe to data changes
try await chat.get(watch: true)
// access all the fetched messages and members
messages = chat.state.messages
members = chat.state.members
// fetch more messages
try await chat.loadOlderMessages()
// access all the fetched messages
messages = chat.state.messages
```

If we would like to observe a single message's state we can use the `MessageState` observable object.

```swift
let messageState = try await chat.messageState(for: messageId)
try await chat.loadMoreReplies(for: messageId)
// access all the fetched replies
let replies = messageState.replies 
```

:::tip Call get with watch true once per app lifetime
The get method fetches the latest state from the Stream API and if we set watch to true, server-side events will keep your local state up to state.
:::

### ConnectedUser

`ConnectedUser` and its `ConnectedUserState` represent the currently logged in user. We can set up push notifications and set states, like muting a user in every channel. Another common use-case is marking all the channels as read.

```swift
var connectedUser = try await chatClient.connectUser(
    userInfo: UserInfo(id: "<# Your User ID Here #>"),
    token: "<# Your User Token Here#>"
)
// or while being logged in
connectedUser = try chatClient.makeConnectedUser()
// register for push notifications
try await connectedUser.addDevice(
    .apn(
        token: apnTokenData, 
        providerName: "<# Your Stream's Push Configuration Name>"
    )
)
try await connectedUser.markAllChannelsRead()
```

### MemberList

`MemberList` and `MemberListState` represent channel members for the specified query. The query supports a wide variety of filters and sorting options. While `MemberList` provides advanced querying capabilities, it is not required if we would like to load all the channel members. For that purpose, `Chat` has built-in paginated loading methods for all the channel members.

```swift
let query = ChannelMemberListQuery(
        cid: ChannelId(type: .messaging, id: "general"),
        sort: [Sorting(key: .createdAt, isAscending: true)]
    )
let memberList = chatClient.makeMemberList(with: query)
// local state of the member list (state from previous sessions)
var members = memberList.state.members
// fetch the first page of members from the Stream API
try await memberList.get()
// fetch more members
try await memberList.loadMoreMembers()
// access all the fetched members
members = memberList.state.members
```

### MessageSearch

`MessageSearch` and `MessageSearchState` represent search results for messages. Messages can be searched using a combination of filters or just by a simple search term.

```swift
let messageSearch = chatClient.makeMessageSearch()
// searching for messages containing "Stream"
try await messageSearch.search(text: "Stream")
// or searching for messages in the specified channel containing "Stream"
try await messageSearch.search(query:
    MessageSearchQuery(
        channelFilter: .containMembers(userIds: ["john"]),
        messageFilter: .autocomplete(.text, text: "Stream")
    )
)
// fetch more results
try await messageSearch.loadMoreMessages()
// all the fetched results
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
// fetch reactions for the query
try await reactionList.get()
// load more reactions
try await reactionList.loadMoreReactions()
// all the loaded reactions
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
// fetch users for the query
try await userList.get()
// load more users
try await userList.loadMoreUsers()
// all the loaded users
let users = userList.state.users
```

### UserSearch

`UserSearch` and `UserSearchState` represent user search results. Although `UserList` and `UserSearch` are similar and use the same `UserListQuery`, the main difference is that `UserSearch` is optimized for interactive searching where the query changes often.

```swift
let userSearch = chatClient.makeUserSearch()
try await userSearch.search(term: "thi")
// fetch more results
try await userSearch.loadMoreUsers()
// all the fetched results for "thi"
var users = userSearch.state.users
// change the search term
try await userSearch.search(term: "thie")
// all the fetched results for "thie"
users = userSearch.state.users
```